// GeoPoint.swift
// 地理点数据模型
// 见 PHASE_V0_SPEC.md

import Foundation

/// 点位类型
enum PointType: String, Codable {
    case origin      // 原点
    case destination // 终点
}

/// 地理点（原点或终点）
struct GeoPoint: Identifiable, Codable {
    let id: String
    let name: String
    let coordinate: WGS84Coordinate
    let pointType: PointType

    init(id: String = UUID().uuidString, name: String, coordinate: WGS84Coordinate, pointType: PointType) {
        self.id = id
        self.name = name
        self.coordinate = coordinate
        self.pointType = pointType
    }
}

/// 连线信息（扩展版）
struct Connection {
    let origin: GeoPoint
    let destination: GeoPoint
    let distance: Double        // 米
    let bearing: Double         // 0-360°
    let mountain: Mountain      // 24山
    let trigram: Trigram        // 八卦
    let wuxing: WuXing          // 五行

    /// 格式化距离显示
    var formattedDistance: String {
        if distance < 1000 {
            return String(format: "%.0f米", distance)
        } else {
            return String(format: "%.2f公里", distance / 1000.0)
        }
    }

    /// 格式化方位角显示
    var formattedBearing: String {
        return String(format: "%.1f°", bearing)
    }
}
