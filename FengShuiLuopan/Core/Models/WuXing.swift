// WuXing.swift
// 五行数据模型

import Foundation

/// 五行
enum WuXing: String {
    case jin = "金"    // 金
    case mu = "木"     // 木
    case shui = "水"   // 水
    case huo = "火"    // 火
    case tu = "土"     // 土

    /// 24山对应的五行
    /// 见传统风水理论
    static func fromMountain(_ mountain: Mountain) -> WuXing {
        switch mountain.name {
        // 金
        case "庚", "辛", "申", "酉":
            return .jin
        // 木
        case "甲", "乙", "寅", "卯":
            return .mu
        // 水
        case "壬", "癸", "亥", "子":
            return .shui
        // 火
        case "丙", "丁", "巳", "午":
            return .huo
        // 土
        case "辰", "戌", "丑", "未", "艮", "坤", "巽", "乾":
            return .tu
        default:
            return .tu  // 默认土
        }
    }

    /// 根据方位角查找对应的五行
    static func fromBearing(_ bearing: Double) -> WuXing {
        let mountain = Mountain.fromBearing(bearing)
        return fromMountain(mountain)
    }
}
