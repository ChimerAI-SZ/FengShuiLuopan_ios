// GeoPoint.swift
// 地理点数据模型
// 见 PHASE_V0_SPEC.md, PHASE_V1_SPEC.md, PHASE_V2_SPEC.md

import Foundation

/// 点位类型
enum PointType: String, Codable {
    case origin      // 原点
    case destination // 终点
    case gpsOrigin   // GPS原点（Phase 1预留）
}

/// 罗盘模式（Phase 1）
enum CompassMode: String, Codable {
    case locked   // 锁定模式：罗盘固定在地理坐标
    case unlocked // 解锁模式：罗盘固定在屏幕中心
}

/// 地理点（原点或终点）- Phase 2完整版
struct GeoPoint: Identifiable, Codable {
    let id: Int
    let caseId: Int
    var name: String
    var coordinate: WGS84Coordinate
    let pointType: PointType
    let isGPSOrigin: Bool
    let createdAt: Date
    var updatedAt: Date

    init(
        id: Int,
        caseId: Int,
        name: String,
        coordinate: WGS84Coordinate,
        pointType: PointType,
        isGPSOrigin: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.caseId = caseId
        self.name = name
        self.coordinate = coordinate
        self.pointType = pointType
        self.isGPSOrigin = isGPSOrigin
        self.createdAt = createdAt
        self.updatedAt = updatedAt
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

/// GPS原点（Phase 2完整实现）
struct GPSOrigin {
    static let fixedID = -1  // 特殊ID标识GPS原点
    static let fixedName = "当前位置"

    let id: Int
    let caseId: Int
    var coordinate: WGS84Coordinate  // 实时更新
    let name: String
    let isSystemGenerated: Bool

    init(caseId: Int, coordinate: WGS84Coordinate) {
        self.id = GPSOrigin.fixedID
        self.caseId = caseId
        self.coordinate = coordinate
        self.name = GPSOrigin.fixedName
        self.isSystemGenerated = true
    }

    /// 转换为GeoPoint
    func toGeoPoint() -> GeoPoint {
        return GeoPoint(
            id: id,
            caseId: caseId,
            name: name,
            coordinate: coordinate,
            pointType: .origin,
            isGPSOrigin: true
        )
    }
}
