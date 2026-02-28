// FengShuiEngine.swift
// 核心算法引擎
// 见ARCHITECTURE.md 第3节

import Foundation

struct FengShuiEngine {
    // === WGS-84椭球参数 ===
    static let EARTH_RADIUS_A = 6378137.0          // 长半轴（米）
    static let EARTH_RADIUS_B = 6356752.314245     // 短半轴（米）
    static let EARTH_FLATTENING = 1/298.257223563  // 扁率

    // === Rhumb Line方位角计算 ===
    // 见ARCHITECTURE.md 3.1节
    static func calculateRhumbBearing(
        from: WGS84Coordinate,
        to: WGS84Coordinate
    ) -> Double {
        // 同点处理
        if from == to {
            return 0.0
        }

        let φ1 = from.latitudeRadians
        let φ2 = to.latitudeRadians
        let λ1 = from.longitudeRadians
        let λ2 = to.longitudeRadians

        // Mercator纬度差
        let Δφ_prime = log(tan(.pi / 4 + φ2 / 2) / tan(.pi / 4 + φ1 / 2))

        // 经度差（处理跨180°经线）
        var Δλ = λ2 - λ1
        if abs(Δλ) > .pi {
            Δλ = Δλ > 0 ? Δλ - 2 * .pi : Δλ + 2 * .pi
        }

        // 方位角（弧度）
        let θ = atan2(Δλ, Δφ_prime)

        // 转换为度数，归一化到0-360
        var bearing = θ * 180 / .pi
        bearing = bearing.truncatingRemainder(dividingBy: 360)
        if bearing < 0 {
            bearing += 360
        }

        return bearing
    }

    // === Vincenty距离计算 ===
    // 见ARCHITECTURE.md 3.2节
    static func calculateVincentyDistance(
        from: WGS84Coordinate,
        to: WGS84Coordinate
    ) -> Double {
        // 同点处理
        if from == to {
            return 0.0
        }

        let a = EARTH_RADIUS_A
        let b = EARTH_RADIUS_B
        let f = EARTH_FLATTENING

        let φ1 = from.latitudeRadians
        let φ2 = to.latitudeRadians
        let L = to.longitudeRadians - from.longitudeRadians

        let U1 = atan((1 - f) * tan(φ1))
        let U2 = atan((1 - f) * tan(φ2))
        let sinU1 = sin(U1), cosU1 = cos(U1)
        let sinU2 = sin(U2), cosU2 = cos(U2)

        var λ = L
        var λPrev: Double
        var iterLimit = 100
        var cosSqα: Double = 0
        var sinσ: Double = 0
        var cos2σM: Double = 0
        var cosσ: Double = 0
        var σ: Double = 0

        repeat {
            let sinλ = sin(λ)
            let cosλ = cos(λ)
            sinσ = sqrt(pow(cosU2 * sinλ, 2) + pow(cosU1 * sinU2 - sinU1 * cosU2 * cosλ, 2))

            if sinσ == 0 {
                return 0.0  // 重合点
            }

            cosσ = sinU1 * sinU2 + cosU1 * cosU2 * cosλ
            σ = atan2(sinσ, cosσ)
            let sinα = cosU1 * cosU2 * sinλ / sinσ
            cosSqα = 1 - sinα * sinα
            cos2σM = cosσ - 2 * sinU1 * sinU2 / cosSqα

            if cos2σM.isNaN {
                cos2σM = 0  // 赤道线
            }

            let C = f / 16 * cosSqα * (4 + f * (4 - 3 * cosSqα))
            λPrev = λ
            λ = L + (1 - C) * f * sinα * (σ + C * sinσ * (cos2σM + C * cosσ * (-1 + 2 * cos2σM * cos2σM)))

            iterLimit -= 1
        } while abs(λ - λPrev) > 1e-12 && iterLimit > 0

        if iterLimit == 0 {
            // 未收敛，返回近似值
            return 0.0
        }

        let uSq = cosSqα * (a * a - b * b) / (b * b)
        let A = 1 + uSq / 16384 * (4096 + uSq * (-768 + uSq * (320 - 175 * uSq)))
        let B = uSq / 1024 * (256 + uSq * (-128 + uSq * (74 - 47 * uSq)))
        let Δσ = B * sinσ * (cos2σM + B / 4 * (cosσ * (-1 + 2 * cos2σM * cos2σM) -
            B / 6 * cos2σM * (-3 + 4 * sinσ * sinσ) * (-3 + 4 * cos2σM * cos2σM)))

        let s = b * A * (σ - Δσ)

        return s
    }

    // === Rhumb Line正算（扇形终点计算）===
    // 见ARCHITECTURE.md 3.3节
    static func calculateRhumbDestination(
        from: WGS84Coordinate,
        bearing: Double,
        distance: Double
    ) -> WGS84Coordinate {
        let φ1 = from.latitudeRadians
        let λ1 = from.longitudeRadians
        let θ = bearing * .pi / 180  // 转弧度

        let δ = distance / EARTH_RADIUS_A  // 角距离

        let φ2 = φ1 + δ * cos(θ)

        // 检查纬度是否超出范围
        if abs(φ2) > .pi / 2 {
            // 超出极地，返回极点
            let lat = φ2 > 0 ? 90.0 : -90.0
            return WGS84Coordinate(latitude: lat, longitude: from.longitude)
        }

        let Δφ_prime = log(tan(.pi / 4 + φ2 / 2) / tan(.pi / 4 + φ1 / 2))
        let q = abs(Δφ_prime) > 1e-12 ? (φ2 - φ1) / Δφ_prime : cos(φ1)

        let Δλ = δ * sin(θ) / q
        let λ2 = λ1 + Δλ

        // 转换为度数
        var lat = φ2 * 180 / .pi
        var lon = λ2 * 180 / .pi

        // 归一化经度到-180~180
        lon = lon.truncatingRemainder(dividingBy: 360)
        if lon > 180 {
            lon -= 360
        } else if lon < -180 {
            lon += 360
        }

        // 限制纬度到-90~90
        lat = max(-90, min(90, lat))

        return WGS84Coordinate(latitude: lat, longitude: lon)
    }

    // === 方位角转24山 ===
    static func bearingToMountain(_ bearing: Double) -> Mountain {
        return Mountain.fromBearing(bearing)
    }

    // === 方位角转八卦 ===
    static func bearingToTrigram(_ bearing: Double) -> Trigram {
        return Trigram.fromBearing(bearing)
    }

    // === 方位角转五行 ===
    static func bearingToWuXing(_ bearing: Double) -> WuXing {
        return WuXing.fromBearing(bearing)
    }
}
