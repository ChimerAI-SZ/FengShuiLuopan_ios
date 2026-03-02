// MapViewModel.swift
// 地图视图模型 - Phase 2版本
// 见 PHASE_V0_SPEC.md, PHASE_V1_SPEC.md, PHASE_V2_SPEC.md

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

    // MARK: - Private Properties

    private var mapController: MapControllerProtocol?
    private let service: FengShuiService
    private var cancellables = Set<AnyCancellable>()
    private var gpsOrigin: GPSOrigin?

    // MARK: - Initialization

    init() {
        do {
            self.service = try FengShuiService()
        } catch {
            self.service = try! FengShuiService()
            self.errorMessage = "初始化失败: \(error.localizedDescription)"
        }
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
        mapController?.removeAllPolylines()

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
}
