// MapViewModel.swift
// 地图视图模型 - Phase 1版本
// 见 PHASE_V0_SPEC.md, PHASE_V1_SPEC.md

import Foundation
import Combine

/// 地图视图模型
/// Phase 0: 单原点 + 单终点
/// Phase 1: 罗盘模式 + 定位按钮
class MapViewModel: ObservableObject {

    // MARK: - Published Properties

    /// 当前原点
    @Published var origin: GeoPoint?

    /// 当前终点
    @Published var destination: GeoPoint?

    /// 连线信息
    @Published var connection: Connection?

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

    // MARK: - Private Properties

    private var mapController: MapControllerProtocol?
    private var pointCounter: Int = 0

    // MARK: - Initialization

    init() {}

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

    // MARK: - User Actions

    /// 添加原点（通过屏幕中心或加号按钮）
    func addOriginAtCenter() {
        guard let center = mapCenterCoordinate else { return }
        addOrigin(at: center)
    }

    /// 添加原点
    func addOrigin(at coordinate: WGS84Coordinate) {
        pointCounter += 1
        let point = GeoPoint(
            name: "原点\(pointCounter)",
            coordinate: coordinate,
            pointType: .origin
        )
        origin = point

        // 添加标记
        mapController?.addMarker(id: point.id, at: coordinate, icon: .origin)

        // 如果已有终点，计算连线
        if let dest = destination {
            calculateConnection(from: point, to: dest)
            // 罗盘出现在原点处
            renderCompass(at: coordinate)
        } else {
            // 罗盘出现在原点处
            renderCompass(at: coordinate)
        }
    }

    /// 添加终点（通过屏幕中心或加号按钮）
    func addDestinationAtCenter() {
        guard let center = mapCenterCoordinate else { return }
        addDestination(at: center)
    }

    /// 添加终点
    func addDestination(at coordinate: WGS84Coordinate) {
        pointCounter += 1
        let point = GeoPoint(
            name: "终点\(pointCounter)",
            coordinate: coordinate,
            pointType: .destination
        )
        destination = point

        // 添加标记
        mapController?.addMarker(id: point.id, at: coordinate, icon: .destination)

        // 如果已有原点，计算连线
        if let orig = origin {
            calculateConnection(from: orig, to: point)
            // 视角移回原点
            mapController?.moveCamera(to: orig.coordinate, zoom: currentZoom, animated: true)
            // 罗盘出现在原点处
            renderCompass(at: orig.coordinate)
        }
    }

    /// 清除所有
    func clearAll() {
        origin = nil
        destination = nil
        connection = nil
        showConnectionPanel = false
        pointCounter = 0

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
            // TODO: 显示提示"无法获取当前位置"
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
            // 罗盘将在MapView中以UIView形式显示在屏幕中心

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

    // MARK: - Private Methods

    /// 处理地图点击
    private func handleMapTap(at coordinate: WGS84Coordinate) {
        // Phase 0: 地图点击不添加点，只通过加号按钮或十字指示添加
        // 保留此方法以便后续扩展
    }

    /// 处理标记点击
    private func handleMarkerTap(markerId: String) {
        showConnectionPanel.toggle()
    }

    /// 计算连线信息
    private func calculateConnection(from origin: GeoPoint, to destination: GeoPoint) {
        // 计算方位角（Rhumb Line）
        let bearing = FengShuiEngine.calculateRhumbBearing(
            from: origin.coordinate,
            to: destination.coordinate
        )

        // 计算距离（Vincenty）
        let distance = FengShuiEngine.calculateVincentyDistance(
            from: origin.coordinate,
            to: destination.coordinate
        )

        // 映射到24山
        let mountain = Mountain.fromBearing(bearing)

        // 映射到八卦
        let trigram = Trigram.fromBearing(bearing)

        // 映射到五行
        let wuxing = WuXing.fromMountain(mountain)

        // 创建连线信息
        connection = Connection(
            origin: origin,
            destination: destination,
            distance: distance,
            bearing: bearing,
            mountain: mountain,
            trigram: trigram,
            wuxing: wuxing
        )

        // 绘制连线（红色，12像素宽）
        let style = PolylineStyle(
            color: 0xFFE53935,  // #E53935 红色
            width: 12.0,
            isDashed: false
        )
        mapController?.addPolyline(
            id: "connection",
            points: [origin.coordinate, destination.coordinate],
            style: style
        )

        // 显示信息面板
        showConnectionPanel = true
    }

    /// 渲染罗盘（GroundOverlay）
    private func renderCompass(at coordinate: WGS84Coordinate) {
        // 生成罗盘图片
        let compassImage = CompassImageGenerator.generateCompassImage(size: 1000)

        // 罗盘半径（米）- 根据缩放级别调整
        let radiusMeters: Double = 100.0

        // 添加GroundOverlay
        mapController?.addGroundOverlay(
            id: "compass",
            center: coordinate,
            image: compassImage,
            radiusMeters: radiusMeters
        )
    }
}
