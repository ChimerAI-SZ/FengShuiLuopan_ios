// CoordinateConverter.swift
// WGS-84 ↔ GCJ-02 坐标转换
// 见ARCHITECTURE.md 4.3节

import Foundation

struct CoordinateConverter {
    // 克拉索夫斯基椭球参数
    private static let a = 6378245.0
    private static let ee = 0.00669342162296594323

    /// 判断是否在中国境内
    static func isInChina(_ coord: WGS84Coordinate) -> Bool {
        let lat = coord.latitude
        let lon = coord.longitude
        // 简化判断：经度73.66-135.05，纬度3.86-53.55
        return lon >= 73.66 && lon <= 135.05 && lat >= 3.86 && lat <= 53.55
    }

    /// WGS-84 → GCJ-02（火星坐标系）
    static func wgs84ToGcj02(_ coord: WGS84Coordinate) -> WGS84Coordinate {
        // 不在中国境内，不转换
        if !isInChina(coord) {
            return coord
        }

        let lat = coord.latitude
        let lon = coord.longitude

        var dLat = transformLat(lon - 105.0, lat - 35.0)
        var dLon = transformLon(lon - 105.0, lat - 35.0)

        let radLat = lat / 180.0 * .pi
        var magic = sin(radLat)
        magic = 1 - ee * magic * magic
        let sqrtMagic = sqrt(magic)

        dLat = (dLat * 180.0) / ((a * (1 - ee)) / (magic * sqrtMagic) * .pi)
        dLon = (dLon * 180.0) / (a / sqrtMagic * cos(radLat) * .pi)

        let mgLat = lat + dLat
        let mgLon = lon + dLon

        return WGS84Coordinate(latitude: mgLat, longitude: mgLon)
    }

    /// GCJ-02 → WGS-84（逆转换）
    static func gcj02ToWgs84(_ coord: WGS84Coordinate) -> WGS84Coordinate {
        // 不在中国境内，不转换
        if !isInChina(coord) {
            return coord
        }

        // 使用迭代法逆转换
        var wgs = coord
        for _ in 0..<10 {
            let gcj = wgs84ToGcj02(wgs)
            let dLat = coord.latitude - gcj.latitude
            let dLon = coord.longitude - gcj.longitude

            wgs = WGS84Coordinate(
                latitude: wgs.latitude + dLat,
                longitude: wgs.longitude + dLon
            )

            // 精度足够，退出
            if abs(dLat) < 1e-8 && abs(dLon) < 1e-8 {
                break
            }
        }

        return wgs
    }

    // === 私有辅助函数 ===

    private static func transformLat(_ x: Double, _ y: Double) -> Double {
        var ret = -100.0 + 2.0 * x + 3.0 * y + 0.2 * y * y + 0.1 * x * y + 0.2 * sqrt(abs(x))
        ret += (20.0 * sin(6.0 * x * .pi) + 20.0 * sin(2.0 * x * .pi)) * 2.0 / 3.0
        ret += (20.0 * sin(y * .pi) + 40.0 * sin(y / 3.0 * .pi)) * 2.0 / 3.0
        ret += (160.0 * sin(y / 12.0 * .pi) + 320 * sin(y * .pi / 30.0)) * 2.0 / 3.0
        return ret
    }

    private static func transformLon(_ x: Double, _ y: Double) -> Double {
        var ret = 300.0 + x + 2.0 * y + 0.1 * x * x + 0.1 * x * y + 0.1 * sqrt(abs(x))
        ret += (20.0 * sin(6.0 * x * .pi) + 20.0 * sin(2.0 * x * .pi)) * 2.0 / 3.0
        ret += (20.0 * sin(x * .pi) + 40.0 * sin(x / 3.0 * .pi)) * 2.0 / 3.0
        ret += (150.0 * sin(x / 12.0 * .pi) + 300.0 * sin(x / 30.0 * .pi)) * 2.0 / 3.0
        return ret
    }
}
