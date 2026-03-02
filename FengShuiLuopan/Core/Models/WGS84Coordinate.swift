// WGS84Coordinate.swift
// 基础坐标类型 - WGS-84坐标系
// 见ARCHITECTURE.md 4.3节

import Foundation

/// WGS-84坐标（世界大地测量系统1984）
struct WGS84Coordinate: Equatable, Codable, CustomStringConvertible {
    let latitude: Double   // 纬度 -90 ~ 90
    let longitude: Double  // 经度 -180 ~ 180

    init(latitude: Double, longitude: Double) {
        // 验证范围
        precondition(latitude >= -90 && latitude <= 90,
                     "纬度超出范围: \(latitude)，有效范围 -90 ~ 90")
        precondition(longitude >= -180 && longitude <= 180,
                     "经度超出范围: \(longitude)，有效范围 -180 ~ 180")

        self.latitude = latitude
        self.longitude = longitude
    }

    var description: String {
        return String(format: "(%.6f°, %.6f°)", latitude, longitude)
    }

    /// 转换为弧度
    var latitudeRadians: Double { latitude * .pi / 180.0 }
    var longitudeRadians: Double { longitude * .pi / 180.0 }
}
