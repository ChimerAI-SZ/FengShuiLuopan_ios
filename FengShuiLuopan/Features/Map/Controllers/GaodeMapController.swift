// GaodeMapController.swift
// 高德地图控制器实现
// 见 ARCHITECTURE.md 4.2节

import Foundation
import CoreGraphics
import AMapFoundationKit
import MAMapKit

/// 高德地图控制器
/// 实现MapControllerProtocol，封装高德SDK
class GaodeMapController: NSObject, MapControllerProtocol {

    // MARK: - Properties

    private let mapView: MAMapView
    private let converter: CoordinateConverter

    /// 标记点缓存 (id -> MAPointAnnotation)
    private var markers: [String: MAPointAnnotation] = [:]

    /// 覆盖层缓存 (id -> MAOverlay)
    private var overlays: [String: MAOverlay] = [:]

    /// 连线缓存 (id -> MAPolyline)
    private var polylines: [String: MAPolyline] = [:]

    // MARK: - Callbacks

    var onMapTap: ((WGS84Coordinate) -> Void)?
    var onMarkerTap: ((String) -> Void)?
    var onCameraMove: ((WGS84Coordinate, Float) -> Void)?

    // MARK: - SDK Type

    var sdkType: MapSDKType { .gaode }

    // MARK: - Initialization

    init(mapView: MAMapView) {
        self.mapView = mapView
        self.converter = CoordinateConverter()
        super.init()

        // 配置地图
        mapView.delegate = self
        mapView.showsUserLocation = true
        mapView.userTrackingMode = .none
        mapView.isRotateEnabled = false  // 禁用旋转
        mapView.isRotateCameraEnabled = false
    }

    // MARK: - Camera Control

    func moveCamera(to coordinate: WGS84Coordinate, zoom: Float, animated: Bool) {
        // WGS-84 → GCJ-02
        let gcj = converter.wgs84ToGcj02(coordinate)
        let center = CLLocationCoordinate2D(latitude: gcj.latitude, longitude: gcj.longitude)

        mapView.setCenter(center, animated: animated)
        mapView.setZoomLevel(CGFloat(zoom), animated: animated)
    }

    func getCurrentCenter() -> WGS84Coordinate {
        // GCJ-02 → WGS-84
        let center = mapView.centerCoordinate
        let gcj = WGS84Coordinate(latitude: center.latitude, longitude: center.longitude)
        return converter.gcj02ToWgs84(gcj)
    }

    func getCurrentZoom() -> Float {
        return Float(mapView.zoomLevel)
    }

    // MARK: - Markers

    func addMarker(id: String, at coordinate: WGS84Coordinate, icon: MarkerIcon) -> String {
        // 移除旧标记（如果存在）
        if let oldMarker = markers[id] {
            mapView.removeAnnotation(oldMarker)
        }

        // WGS-84 → GCJ-02
        let gcj = converter.wgs84ToGcj02(coordinate)
        let annotation = MAPointAnnotation()
        annotation.coordinate = CLLocationCoordinate2D(latitude: gcj.latitude, longitude: gcj.longitude)
        annotation.title = id

        markers[id] = annotation
        mapView.addAnnotation(annotation)

        return id
    }

    func removeMarker(id: String) {
        guard let marker = markers[id] else { return }
        mapView.removeAnnotation(marker)
        markers.removeValue(forKey: id)
    }

    func removeAllMarkers() {
        mapView.removeAnnotations(Array(markers.values))
        markers.removeAll()
    }

    // MARK: - Overlays

    func addGroundOverlay(id: String, center: WGS84Coordinate, image: UIImage, radiusMeters: Double) {
        // 移除旧覆盖层
        if let oldOverlay = overlays[id] {
            mapView.removeOverlay(oldOverlay)
        }

        // WGS-84 → GCJ-02
        let gcj = converter.wgs84ToGcj02(center)
        let centerCoord = CLLocationCoordinate2D(latitude: gcj.latitude, longitude: gcj.longitude)

        // 计算边界（正方形）
        let latDelta = radiusMeters / 111320.0
        let lonDelta = radiusMeters / (111320.0 * cos(gcj.latitude * .pi / 180.0))

        let southWest = CLLocationCoordinate2D(
            latitude: gcj.latitude - latDelta,
            longitude: gcj.longitude - lonDelta
        )
        let northEast = CLLocationCoordinate2D(
            latitude: gcj.latitude + latDelta,
            longitude: gcj.longitude + lonDelta
        )

        let bounds = MACoordinateBounds(southWest: southWest, northEast: northEast)
        let groundOverlay = MAGroundOverlay(bounds: bounds, icon: image)

        overlays[id] = groundOverlay
        mapView.addOverlay(groundOverlay)
    }

    func addSectorOverlay(id: String, center: WGS84Coordinate,
                          radiusMeters: Double, startAngle: Double,
                          endAngle: Double, style: OverlayStyle) {
        // 移除旧覆盖层
        if let oldOverlay = overlays[id] {
            mapView.removeOverlay(oldOverlay)
        }

        // WGS-84 → GCJ-02
        let gcj = converter.wgs84ToGcj02(center)
        let centerCoord = CLLocationCoordinate2D(latitude: gcj.latitude, longitude: gcj.longitude)

        // 创建扇形多边形（36段）
        let segments = 36
        var coordinates: [CLLocationCoordinate2D] = [centerCoord]

        let startRad = startAngle * .pi / 180.0
        let endRad = endAngle * .pi / 180.0
        let angleStep = (endRad - startRad) / Double(segments)

        for i in 0...segments {
            let angle = startRad + angleStep * Double(i)
            let lat = gcj.latitude + (radiusMeters / 111320.0) * cos(angle)
            let lon = gcj.longitude + (radiusMeters / (111320.0 * cos(gcj.latitude * .pi / 180.0))) * sin(angle)
            coordinates.append(CLLocationCoordinate2D(latitude: lat, longitude: lon))
        }

        let polygon = MAPolygon(coordinates: &coordinates, count: coordinates.count)
        overlays[id] = polygon
        mapView.addOverlay(polygon)
    }

    func addPolyline(id: String, points: [WGS84Coordinate], style: PolylineStyle) -> String {
        // 移除旧连线
        if let oldPolyline = polylines[id] {
            mapView.removeOverlay(oldPolyline)
        }

        // WGS-84 → GCJ-02
        var coordinates = points.map { wgs in
            let gcj = converter.wgs84ToGcj02(wgs)
            return CLLocationCoordinate2D(latitude: gcj.latitude, longitude: gcj.longitude)
        }

        let polyline = MAPolyline(coordinates: &coordinates, count: coordinates.count)
        polylines[id] = polyline
        mapView.addOverlay(polyline)

        return id
    }

    func removeOverlay(id: String) {
        if let overlay = overlays[id] {
            mapView.removeOverlay(overlay)
            overlays.removeValue(forKey: id)
        }
        if let polyline = polylines[id] {
            mapView.removeOverlay(polyline)
            polylines.removeValue(forKey: id)
        }
    }

    func removeAllOverlays() {
        mapView.removeOverlays(Array(overlays.values))
        mapView.removeOverlays(Array(polylines.values))
        overlays.removeAll()
        polylines.removeAll()
    }

    // MARK: - Geocoding (V4+)

    func geocode(address: String) async throws -> [GeocodingResult] {
        // TODO: Phase 4实现
        return []
    }

    func reverseGeocode(coordinate: WGS84Coordinate) async throws -> String? {
        // TODO: Phase 4实现
        return nil
    }

    // MARK: - Map Type

    func setMapType(_ type: MapLayerType) {
        switch type {
        case .standard:
            mapView.mapType = .standard
        case .satellite:
            mapView.mapType = .satellite
        }
    }

    func getMapType() -> MapLayerType {
        return mapView.mapType == .satellite ? .satellite : .standard
    }

    // MARK: - Screen Coordinate Conversion

    func screenToCoordinate(_ point: CGPoint) -> WGS84Coordinate? {
        let coord = mapView.convert(point, toCoordinateFrom: mapView)
        let gcj = WGS84Coordinate(latitude: coord.latitude, longitude: coord.longitude)
        return converter.gcj02ToWgs84(gcj)
    }

    func coordinateToScreen(_ coordinate: WGS84Coordinate) -> CGPoint? {
        let gcj = converter.wgs84ToGcj02(coordinate)
        let coord = CLLocationCoordinate2D(latitude: gcj.latitude, longitude: gcj.longitude)
        return mapView.convert(coord, toPointTo: mapView)
    }
}

// MARK: - MAMapViewDelegate

extension GaodeMapController: MAMapViewDelegate {

    /// 地图点击
    func mapView(_ mapView: MAMapView!, didSingleTappedAt coordinate: CLLocationCoordinate2D) {
        // GCJ-02 → WGS-84
        let gcj = WGS84Coordinate(latitude: coordinate.latitude, longitude: coordinate.longitude)
        let wgs = converter.gcj02ToWgs84(gcj)
        onMapTap?(wgs)
    }

    /// 标记点击
    func mapView(_ mapView: MAMapView!, didSelect view: MAAnnotationView!) {
        guard let annotation = view.annotation as? MAPointAnnotation,
              let id = annotation.title else { return }
        onMarkerTap?(id)
    }

    /// 相机移动
    func mapView(_ mapView: MAMapView!, mapDidMoveByUser wasUserAction: Bool) {
        if wasUserAction {
            let center = getCurrentCenter()
            let zoom = getCurrentZoom()
            onCameraMove?(center, zoom)
        }
    }

    /// 自定义标记视图
    func mapView(_ mapView: MAMapView!, viewFor annotation: MAAnnotation!) -> MAAnnotationView! {
        if annotation is MAUserLocation {
            return nil
        }

        let reuseId = "marker"
        var view = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MAPinAnnotationView

        if view == nil {
            view = MAPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            view?.canShowCallout = false
        } else {
            view?.annotation = annotation
        }

        return view
    }

    /// 自定义覆盖层渲染
    func mapView(_ mapView: MAMapView!, rendererFor overlay: MAOverlay!) -> MAOverlayRenderer! {
        // GroundOverlay（罗盘图片）
        if let groundOverlay = overlay as? MAGroundOverlay {
            let renderer = MAGroundOverlayRenderer(groundOverlay: groundOverlay)
            return renderer
        }

        // Polygon（扇形）
        if let polygon = overlay as? MAPolygon {
            let renderer = MAPolygonRenderer(polygon: polygon)
            renderer.fillColor = UIColor(red: 1.0, green: 0.0, blue: 0.0, alpha: 0.3)
            renderer.strokeColor = UIColor.red
            renderer.lineWidth = 2.0
            return renderer
        }

        if let polyline = overlay as? MAPolyline {
            let renderer = MAPolylineRenderer(polyline: polyline)
            renderer.strokeColor = UIColor.blue
            renderer.lineWidth = 3.0
            return renderer
        }

        return nil
    }
}
