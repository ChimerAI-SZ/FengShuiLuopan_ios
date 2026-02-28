// MapControllerProtocol.swift
// 地图控制器协议 - 抽象地图SDK
// 见 ARCHITECTURE.md 4.2.2节

import Foundation
import CoreGraphics
import UIKit

/// 地图SDK类型
enum MapSDKType {
    case gaode    // 高德地图（国内）
    case google   // Google Maps（海外，V5+）
}

/// 地图图层类型
enum MapLayerType {
    case standard   // 标准地图
    case satellite  // 卫星地图
}

/// 标记点图标类型
enum MarkerIcon {
    case origin     // 原点标记
    case destination // 终点标记
    case poi        // POI标记
    case custom(imageName: String)
}

/// 覆盖层样式
struct OverlayStyle {
    let fillColor: UInt32      // ARGB格式
    let strokeColor: UInt32    // ARGB格式
    let strokeWidth: Float
}

/// 连线样式
struct PolylineStyle {
    let color: UInt32          // ARGB格式
    let width: Float
    let isDashed: Bool
}

/// 地理编码结果（V4+）
struct GeocodingResult {
    let coordinate: WGS84Coordinate
    let formattedAddress: String
    let name: String?
}

/// 地图控制器协议
/// 所有地图SDK实现必须遵循此协议
/// 协议内部使用WGS-84坐标，具体实现负责坐标转换
protocol MapControllerProtocol: AnyObject {

    // MARK: - 相机控制 (V1)

    /// 移动相机到指定位置
    /// - Parameters:
    ///   - coordinate: WGS-84坐标
    ///   - zoom: 缩放级别 (3-20)
    ///   - animated: 是否动画
    func moveCamera(to coordinate: WGS84Coordinate, zoom: Float, animated: Bool)

    /// 获取当前地图中心坐标（WGS-84）
    func getCurrentCenter() -> WGS84Coordinate

    /// 获取当前缩放级别
    func getCurrentZoom() -> Float

    // MARK: - 标记点 (V1)

    /// 添加标记点
    /// - Parameters:
    ///   - id: 标记点唯一ID
    ///   - coordinate: WGS-84坐标
    ///   - icon: 图标类型
    /// - Returns: 标记点ID
    @discardableResult
    func addMarker(id: String, at coordinate: WGS84Coordinate, icon: MarkerIcon) -> String

    /// 移除标记点
    func removeMarker(id: String)

    /// 移除所有标记点
    func removeAllMarkers()

    // MARK: - 覆盖层 (V2+)

    /// 添加地面覆盖层（罗盘图片）
    /// - Parameters:
    ///   - id: 覆盖层唯一ID
    ///   - center: 中心点WGS-84坐标
    ///   - image: 覆盖层图片
    ///   - radiusMeters: 半径（米）
    func addGroundOverlay(id: String, center: WGS84Coordinate, image: UIImage, radiusMeters: Double)

    /// 添加扇形覆盖层（罗盘扇形）
    /// - Parameters:
    ///   - id: 覆盖层唯一ID
    ///   - center: 中心点WGS-84坐标
    ///   - radiusMeters: 半径（米）
    ///   - startAngle: 起始角度（度，正北为0°，顺时针）
    ///   - endAngle: 结束角度（度）
    ///   - style: 样式
    func addSectorOverlay(id: String, center: WGS84Coordinate,
                          radiusMeters: Double, startAngle: Double,
                          endAngle: Double, style: OverlayStyle)

    /// 添加连线
    /// - Parameters:
    ///   - id: 连线唯一ID
    ///   - points: WGS-84坐标数组
    ///   - style: 连线样式
    /// - Returns: 连线ID
    @discardableResult
    func addPolyline(id: String, points: [WGS84Coordinate], style: PolylineStyle) -> String

    /// 移除覆盖层
    func removeOverlay(id: String)

    /// 移除所有覆盖层
    func removeAllOverlays()

    // MARK: - 地理编码 (V4+)

    /// 地址转坐标
    func geocode(address: String) async throws -> [GeocodingResult]

    /// 坐标转地址
    func reverseGeocode(coordinate: WGS84Coordinate) async throws -> String?

    // MARK: - 地图类型

    /// 设置地图类型
    func setMapType(_ type: MapLayerType)

    /// 获取当前地图类型
    func getMapType() -> MapLayerType

    // MARK: - 屏幕坐标转换

    /// 屏幕坐标转地理坐标
    func screenToCoordinate(_ point: CGPoint) -> WGS84Coordinate?

    /// 地理坐标转屏幕坐标
    func coordinateToScreen(_ coordinate: WGS84Coordinate) -> CGPoint?

    // MARK: - 回调

    /// 地图点击回调（返回WGS-84坐标）
    var onMapTap: ((WGS84Coordinate) -> Void)? { get set }

    /// 标记点击回调
    var onMarkerTap: ((String) -> Void)? { get set }

    /// 相机移动回调
    var onCameraMove: ((WGS84Coordinate, Float) -> Void)? { get set }

    // MARK: - SDK标识

    /// SDK类型（用于V5+切换判断）
    var sdkType: MapSDKType { get }
}
