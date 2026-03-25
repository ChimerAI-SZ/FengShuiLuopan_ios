// MapViewModel.swift
// 地图视图模型 - Phase 4版本
// 见 PHASE_V0_SPEC.md, PHASE_V1_SPEC.md, PHASE_V2_SPEC.md, PHASE_V4_SPEC.md

import Foundation
import Combine
import UIKit

/// 地图视图模型
/// Phase 2: 多原点多终点 + 案例管理 + GPS原点
class MapViewModel: ObservableObject {

    // MARK: - Published Properties

    /// 当前案例ID
    @Published var currentCaseId: Int?

    /// 当前选中的原点
    @Published var selectedOrigin: GeoPoint?

    /// 当前选中的终点列表
    @Published var selectedDestinations: [GeoPoint] = []

    /// 连线信息列表
    @Published var connections: [Connection] = []

    /// 是否显示连线信息面板
    @Published var showConnectionPanel: Bool = false

    /// 当前地图中心坐标（用于添加点）
    @Published var mapCenterCoordinate: WGS84Coordinate?

    /// 当前缩放级别
    @Published var currentZoom: Float = 15.0

    /// 地图类型
    @Published var mapType: MapLayerType = .standard

    /// 罗盘模式（Phase 1）
    @Published var compassMode: CompassMode = .locked

    /// 罗盘坐标（锁定模式下使用）
    @Published var compassCoordinate: WGS84Coordinate?

    /// 显示加点对话框
    @Published var showAddPointDialog: Bool = false

    /// 显示原点选择器
    @Published var showOriginSelector: Bool = false

    /// 显示终点选择器
    @Published var showDestinationSelector: Bool = false

    /// 错误消息
    @Published var errorMessage: String?

    /// 扇形搜索相关状态（Phase 3）
    @Published var showSectorSearch: Bool = false
    @Published var isCrosshairMode: Bool = false
    @Published var crosshairPOIName: String = ""
    @Published var crosshairPOIAddress: String = ""
    @Published var activePOIMarkers: [POIResult] = []
    @Published var sectorSearchMessage: String?

    // MARK: - Private Properties

    private var mapController: MapControllerProtocol?
    private let service: FengShuiService
    private var cancellables = Set<AnyCancellable>()
    private var gpsOrigin: GPSOrigin?

    /// 扇形搜索视图模型（Phase 3）
    let sectorSearchViewModel = SectorSearchViewModel()

    /// POI搜索服务（Phase 3）
    let poiSearchService = POISearchService()

    /// 生活圈视图模型（Phase 4）
    let lifeCircleViewModel = LifeCircleViewModel()

    /// 是否在生活圈模式
    @Published var isInLifeCircleMode: Bool = false

    /// 显示生活圈向导（多选原点）
    @Published var showLifeCircleWizard: Bool = false

    /// 生活圈激活前保存的普通模式状态（用于恢复）
    private var savedNormalModeState: (origin: GeoPoint?, destinations: [GeoPoint], connections: [Connection])? = nil

    /// 显示设置页面（Phase 5）
    @Published var showSettings: Bool = false

    // MARK: - Initialization

    init() {
        do {
            self.service = try FengShuiService()
        } catch {
            self.service = try! FengShuiService()
            self.errorMessage = "初始化失败: \(error.localizedDescription)"
        }

        // 监听扇形搜索结果消息
        sectorSearchViewModel.$searchResultMessage
            .receive(on: DispatchQueue.main)
            .sink { [weak self] message in
                self?.sectorSearchMessage = message
            }
            .store(in: &cancellables)
    }

    // MARK: - GPS Origin Management

    /// 设置位置服务（用于GPS原点）
    func setupLocationService(_ locationService: LocationService) {
        // 监听位置更新
        locationService.$currentLocation
            .compactMap { $0 }
            .sink { [weak self] coordinate in
                self?.updateGPSOrigin(coordinate: coordinate)
            }
            .store(in: &cancellables)
    }

    /// 更新GPS原点坐标
    private func updateGPSOrigin(coordinate: WGS84Coordinate) {
        guard let caseId = currentCaseId else { return }

        // 更新或创建GPS原点
        if gpsOrigin == nil {
            gpsOrigin = GPSOrigin(caseId: caseId, coordinate: coordinate)
        } else {
            gpsOrigin?.coordinate = coordinate
        }

        // 如果当前选中的是GPS原点，重新计算连线
        if let origin = selectedOrigin, origin.isGPSOrigin {
            selectedOrigin = gpsOrigin?.toGeoPoint()
            calculateConnections()

            // 更新罗盘位置
            if compassMode == .locked {
                renderCompass(at: coordinate)
            }
        }
    }

    // MARK: - Map Controller Setup

    /// 设置地图控制器
    func setMapController(_ controller: MapControllerProtocol) {
        self.mapController = controller

        // 设置回调
        controller.onMapTap = { [weak self] coordinate in
            self?.handleMapTap(at: coordinate)
        }

        controller.onMarkerTap = { [weak self] markerId in
            self?.handleMarkerTap(markerId: markerId)
        }

        controller.onCameraMove = { [weak self] center, zoom in
            self?.mapCenterCoordinate = center
            self?.currentZoom = zoom
        }
    }

    // MARK: - Point Management

    /// 显示加点对话框
    func showAddPoint() {
        showAddPointDialog = true
    }

    /// 添加点位
    func addPoint(name: String, caseId: Int, pointType: PointType) {
        guard let coordinate = mapCenterCoordinate else { return }

        do {
            let point = try service.createPoint(
                caseId: caseId,
                name: name,
                coordinate: coordinate,
                pointType: pointType
            )

            // 设置当前案例
            currentCaseId = caseId

            // 添加标记
            let icon: MarkerIcon = pointType == .origin ? .origin : .destination
            mapController?.addMarker(id: String(point.id), at: coordinate, icon: icon)

            // 如果是原点，自动选中
            if pointType == .origin {
                selectOrigin(point)
            }

        } catch let error as TrialLimitError {
            errorMessage = error.message
        } catch let error as DuplicatePointError {
            errorMessage = error.message
        } catch {
            errorMessage = "添加点位失败: \(error.localizedDescription)"
        }
    }

    /// 选择原点
    func selectOrigin(_ origin: GeoPoint) {
        selectedOrigin = origin
        currentCaseId = origin.caseId

        // 切换到锁定模式
        compassMode = .locked
        compassCoordinate = origin.coordinate

        // 移动相机到原点
        mapController?.moveCamera(to: origin.coordinate, zoom: 16, animated: true)

        // 渲染罗盘
        renderCompass(at: origin.coordinate)

        // 加载该案例的所有终点
        loadDestinationsForCurrentCase()
    }

    /// 选择终点（多选）
    func selectDestinations(_ destinations: [GeoPoint], origin: GeoPoint) {
        selectedOrigin = origin
        selectedDestinations = destinations
        currentCaseId = origin.caseId

        // 切换到锁定模式
        compassMode = .locked
        compassCoordinate = origin.coordinate

        // 移动相机到原点
        mapController?.moveCamera(to: origin.coordinate, zoom: 16, animated: true)

        // 渲染罗盘
        renderCompass(at: origin.coordinate)

        // 计算并显示连线
        calculateConnections()
    }

    /// 加载当前案例的所有终点
    private func loadDestinationsForCurrentCase() {
        guard let caseId = currentCaseId else { return }

        do {
            let destinations = try service.getDestinationsByCase(caseId)
            selectedDestinations = destinations
            calculateConnections()
        } catch {
            errorMessage = "加载终点失败: \(error.localizedDescription)"
        }
    }

    // MARK: - Connection Calculation

    /// 计算所有连线
    private func calculateConnections() {
        guard let origin = selectedOrigin else { return }

        // 清除旧连线
        connections.removeAll()
        mapController?.removeAllOverlays()

        // 计算每个终点的连线
        for (index, destination) in selectedDestinations.enumerated() {
            let connection = service.calculateConnection(from: origin, to: destination)
            connections.append(connection)

            // 获取连线颜色
            let color = ConnectionColorHelper.getColor(at: index)

            // 绘制连线
            let style = PolylineStyle(
                color: colorToHex(color),
                width: 12.0,
                isDashed: false
            )
            mapController?.addPolyline(
                id: "connection_\(destination.id)",
                points: [origin.coordinate, destination.coordinate],
                style: style
            )
        }

        showConnectionPanel = !connections.isEmpty
    }

    // MARK: - User Actions

    /// 清除所有
    func clearAll() {
        selectedOrigin = nil
        selectedDestinations.removeAll()
        connections.removeAll()
        showConnectionPanel = false

        mapController?.removeAllMarkers()
        mapController?.removeAllOverlays()
    }

    /// 切换地图类型
    func toggleMapType() {
        mapType = (mapType == .standard) ? .satellite : .standard
        mapController?.setMapType(mapType)
    }

    /// 放大
    func zoomIn() {
        guard let center = mapCenterCoordinate else { return }
        let newZoom = min(currentZoom + 1, 20)
        mapController?.moveCamera(to: center, zoom: newZoom, animated: true)
    }

    /// 缩小
    func zoomOut() {
        guard let center = mapCenterCoordinate else { return }
        let newZoom = max(currentZoom - 1, 3)
        mapController?.moveCamera(to: center, zoom: newZoom, animated: true)
    }

    /// 定位到当前位置（Phase 1）
    func moveToCurrentLocation(userLocation: WGS84Coordinate?) {
        guard let location = userLocation else {
            errorMessage = "无法获取当前位置"
            return
        }

        // 移动相机到用户位置
        mapController?.moveCamera(to: location, zoom: 16, animated: true)
    }

    /// 切换罗盘模式（Phase 1）
    func toggleCompassMode() {
        switch compassMode {
        case .locked:
            // 切换到解锁模式
            compassMode = .unlocked
            // 移除GroundOverlay
            mapController?.removeOverlay(id: "compass")

        case .unlocked:
            // 切换到锁定模式
            compassMode = .locked
            // 将罗盘锁定在当前屏幕中心位置
            if let center = mapCenterCoordinate {
                compassCoordinate = center
                renderCompass(at: center)
            }
        }
    }

    // MARK: - Selectors

    /// 显示原点选择器
    func showOriginSelectorDialog() {
        guard let caseId = currentCaseId else {
            errorMessage = "请先选择案例"
            return
        }

        do {
            let origins = try service.getOriginsByCase(caseId)
            if origins.isEmpty {
                errorMessage = "暂无原点，请在堪舆管理中添加"
            } else {
                showOriginSelector = true
            }
        } catch {
            errorMessage = "加载原点失败: \(error.localizedDescription)"
        }
    }

    /// 显示终点选择器
    func showDestinationSelectorDialog() {
        guard let caseId = currentCaseId else {
            errorMessage = "请先选择案例"
            return
        }

        do {
            let destinations = try service.getDestinationsByCase(caseId)
            if destinations.isEmpty {
                errorMessage = "暂无终点，请在堪舆管理中添加"
            } else {
                showDestinationSelector = true
            }
        } catch {
            errorMessage = "加载终点失败: \(error.localizedDescription)"
        }
    }

    /// 获取当前案例的原点列表
    func getOriginsForCurrentCase() -> [GeoPoint] {
        guard let caseId = currentCaseId else { return [] }
        return (try? service.getOriginsByCase(caseId)) ?? []
    }

    /// 获取指定案例的原点列表（Phase 4生活圈用）
    func getOriginsForCase(_ caseId: Int) -> [GeoPoint] {
        return (try? service.getOriginsByCase(caseId)) ?? []
    }

    /// 获取当前案例的终点列表
    func getDestinationsForCurrentCase() -> [GeoPoint] {
        guard let caseId = currentCaseId else { return [] }
        return (try? service.getDestinationsByCase(caseId)) ?? []
    }

    /// 获取所有案例
    func getAllCases() -> [FengShuiCase] {
        return (try? service.getAllCases()) ?? []
    }

    // MARK: - Private Methods

    /// 处理地图点击
    private func handleMapTap(at coordinate: WGS84Coordinate) {
        // Phase 2: 地图点击不添加点，只通过加号按钮或十字指示添加
    }

    /// 处理标记点击
    private func handleMarkerTap(markerId: String) {
        showConnectionPanel.toggle()
    }

    /// 渲染罗盘（GroundOverlay）
    private func renderCompass(at coordinate: WGS84Coordinate) {
        // 生成罗盘图片
        let compassImage = CompassImageGenerator.generateCompassImage(size: 1000)

        // 罗盘半径（米）
        let radiusMeters: Double = 100.0

        // 添加GroundOverlay
        mapController?.addGroundOverlay(
            id: "compass",
            center: coordinate,
            image: compassImage,
            radiusMeters: radiusMeters
        )
    }

    /// 颜色转十六进制
    private func colorToHex(_ color: UIColor) -> UInt32 {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0

        color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)

        let r = UInt32(red * 255)
        let g = UInt32(green * 255)
        let b = UInt32(blue * 255)
        let a = UInt32(alpha * 255)

        return (a << 24) | (r << 16) | (g << 8) | b
    }

    /// 清除错误消息
    func clearError() {
        errorMessage = nil
    }

    // MARK: - Phase 3: 扇形搜索

    /// 扇形起点（有原点用原点，否则用地图中心）
    var sectorOrigin: WGS84Coordinate {
        return selectedOrigin?.coordinate ?? mapCenterCoordinate ?? WGS84Coordinate(latitude: 39.9, longitude: 116.4)
    }

    /// 绘制扇形两翼虚线
    /// - Parameter config: 扇形搜索配置
    func drawSectorWings(config: SectorSearchConfig) {
        let origin = sectorOrigin
        let distance = config.distanceInMeters
        let startAngle = config.startAngle
        let endAngle = config.endAngle

        // 先清除旧的扇形
        mapController?.removeOverlay(id: "sector_left_wing")
        mapController?.removeOverlay(id: "sector_right_wing")

        // 计算左翼终点（startAngle方向）
        let leftEnd = FengShuiEngine.calculateRhumbDestination(
            from: origin,
            bearing: startAngle,
            distance: distance
        )

        // 计算右翼终点（endAngle方向）
        let rightEnd = FengShuiEngine.calculateRhumbDestination(
            from: origin,
            bearing: endAngle,
            distance: distance
        )

        // 虚线样式：紫色半透明
        let wingStyle = PolylineStyle(
            color: UInt32(0x997B1FA2),  // ARGB: 60%透明的紫色 #7B1FA2
            width: 2.5,
            isDashed: true
        )

        // 绘制左翼
        mapController?.addPolyline(
            id: "sector_left_wing",
            points: [origin, leftEnd],
            style: wingStyle
        )

        // 绘制右翼
        mapController?.addPolyline(
            id: "sector_right_wing",
            points: [origin, rightEnd],
            style: wingStyle
        )
    }

    /// 在地图上显示POI标记（最多50个）
    /// - Parameter pois: POI列表
    func showPOIMarkers(_ pois: [POIResult]) {
        // 清除旧的POI标记
        (mapController as? GaodeMapController)?.removeOverlaysByPrefix("poi_marker_")

        // 存储POI结果
        activePOIMarkers = pois

        // 添加新标记（最多50个）
        for poi in pois.prefix(SectorSearchConstants.MAX_POI_COUNT) {
            mapController?.addMarker(
                id: "poi_marker_\(poi.id)",
                at: poi.coordinate,
                icon: .poi
            )
        }
    }

    /// 清除扇形两翼和POI标记
    func clearSector() {
        mapController?.removeOverlay(id: "sector_left_wing")
        mapController?.removeOverlay(id: "sector_right_wing")

        // 清除POI标记
        (mapController as? GaodeMapController)?.removeOverlaysByPrefix("poi_marker_")
        activePOIMarkers = []
        sectorSearchMessage = nil
    }

    // MARK: - Phase 3: 十字准心模式

    /// 进入十字准心模式
    /// - Parameter poi: 来自搜索结果的POI
    func enterCrosshairMode(poi: POIResult) {
        crosshairPOIName = poi.name
        crosshairPOIAddress = poi.address
        isCrosshairMode = true

        // 移动相机到POI位置
        mapController?.moveCamera(to: poi.coordinate, zoom: 16, animated: true)
    }

    /// 保存十字准心位置
    /// - Parameters:
    ///   - caseId: 目标案例ID
    ///   - pointType: 点位类型
    ///   - name: 点位名称
    func saveCrosshairPosition(caseId: Int, pointType: PointType, name: String) {
        guard let center = mapCenterCoordinate else {
            errorMessage = "无法获取地图中心位置"
            return
        }

        do {
            let point = try service.createPoint(
                caseId: caseId,
                name: name,
                coordinate: center,
                pointType: pointType
            )

            // 添加标记
            let icon: MarkerIcon = pointType == .origin ? .origin : .destination
            mapController?.addMarker(id: String(point.id), at: center, icon: icon)

            // 设置当前案例
            currentCaseId = caseId

            // 退出十字准心模式
            exitCrosshairMode()

        } catch let error as TrialLimitError {
            errorMessage = error.message
        } catch let error as DuplicatePointError {
            errorMessage = error.message
        } catch {
            errorMessage = "保存失败: \(error.localizedDescription)"
        }
    }

    /// 退出十字准心模式
    func exitCrosshairMode() {
        isCrosshairMode = false
        crosshairPOIName = ""
        crosshairPOIAddress = ""
    }

    // MARK: - Phase 4: 生活圈模式

    /// 激活生活圈模式
    /// 见 PHASE_V4_SPEC.md 2.1节, ARCHITECTURE.md 10.2节
    func activateLifeCircle(_ lifeCircle: LifeCircleData) {
        // 保存当前普通模式状态（用于退出时恢复）
        savedNormalModeState = (
            origin: selectedOrigin,
            destinations: selectedDestinations,
            connections: connections
        )

        // 隐藏普通模式罗盘和连线
        if compassCoordinate != nil {
            mapController?.removeOverlay(id: "compass")
        }
        mapController?.removeAllOverlays()
        mapController?.removeAllMarkers()

        // 标记进入生活圈模式
        isInLifeCircleMode = true
        showConnectionPanel = false

        // 渲染三个不同尺寸的罗盘
        renderLifeCircleCompasses(lifeCircle)

        // 绘制三角连线
        drawLifeCircleConnections(lifeCircle)
    }

    /// 退出生活圈模式，恢复普通模式
    /// 见 PHASE_V4_SPEC.md 2节退出流程
    func deactivateLifeCircle() {
        // 清除生活圈地图元素
        mapController?.removeOverlay(id: "lc_compass_home")
        mapController?.removeOverlay(id: "lc_compass_work")
        mapController?.removeOverlay(id: "lc_compass_entertainment")
        mapController?.removeOverlay(id: "lc_line_home_work")
        mapController?.removeOverlay(id: "lc_line_work_entertainment")
        mapController?.removeOverlay(id: "lc_line_entertainment_home")

        // 退出生活圈模式
        isInLifeCircleMode = false

        // 恢复普通模式状态
        if let saved = savedNormalModeState {
            selectedOrigin = saved.origin
            selectedDestinations = saved.destinations
            connections = saved.connections
            savedNormalModeState = nil

            // 恢复罗盘（如果之前有选中原点）
            if let origin = saved.origin {
                renderCompass(at: origin.coordinate)
            }

            // 恢复连线
            for (index, conn) in saved.connections.enumerated() {
                let color = ConnectionColorHelper.getColor(at: index)
                let style = PolylineStyle(
                    color: colorToHex(color),
                    width: 12.0,
                    isDashed: false
                )
                mapController?.addPolyline(
                    id: "connection_\(conn.destination.id)",
                    points: [conn.origin.coordinate, conn.destination.coordinate],
                    style: style
                )
            }
            showConnectionPanel = !saved.connections.isEmpty
        }
    }

    /// 渲染生活圈三个不同尺寸的罗盘
    private func renderLifeCircleCompasses(_ lifeCircle: LifeCircleData) {
        let compassTypes: [(GeoPoint, LifeCirclePointType, String)] = [
            (lifeCircle.homePoint, .home, "lc_compass_home"),
            (lifeCircle.workPoint, .work, "lc_compass_work"),
            (lifeCircle.entertainmentPoint, .entertainment, "lc_compass_entertainment")
        ]

        for (point, type, overlayId) in compassTypes {
            let pixelSize = type.compassPixelSize
            let compassImage = CompassImageGenerator.generateCompassImage(size: pixelSize)
            let radius = type.compassRadiusMeters

            mapController?.addGroundOverlay(
                id: overlayId,
                center: point.coordinate,
                image: compassImage,
                radiusMeters: radius
            )
        }
    }

    /// 绘制生活圈三角连线
    /// 见 PHASE_V4_SPEC.md 4.2节, ARCHITECTURE.md 10.4节
    private func drawLifeCircleConnections(_ lifeCircle: LifeCircleData) {
        // 家→公司（绿色 #00C853）
        let homeWorkStyle = PolylineStyle(
            color: LifeCircleConnectionColor.homeToWork,
            width: 12.0,
            isDashed: false
        )
        mapController?.addPolyline(
            id: "lc_line_home_work",
            points: [lifeCircle.homePoint.coordinate, lifeCircle.workPoint.coordinate],
            style: homeWorkStyle
        )

        // 公司→日常场所（蓝色 #2196F3）
        let workEntertainStyle = PolylineStyle(
            color: LifeCircleConnectionColor.workToEntertainment,
            width: 12.0,
            isDashed: false
        )
        mapController?.addPolyline(
            id: "lc_line_work_entertainment",
            points: [lifeCircle.workPoint.coordinate, lifeCircle.entertainmentPoint.coordinate],
            style: workEntertainStyle
        )

        // 日常场所→家（橙色 #FF9800）
        let entertainHomeStyle = PolylineStyle(
            color: LifeCircleConnectionColor.entertainmentToHome,
            width: 12.0,
            isDashed: false
        )
        mapController?.addPolyline(
            id: "lc_line_entertainment_home",
            points: [lifeCircle.entertainmentPoint.coordinate, lifeCircle.homePoint.coordinate],
            style: entertainHomeStyle
        )
    }
