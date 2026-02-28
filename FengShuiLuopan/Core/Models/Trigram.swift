// Trigram.swift
// 八卦数据模型
// 见ARCHITECTURE.md 3.6节

import Foundation

/// 八卦（八方位）
struct Trigram {
    let name: String         // 如"坎"
    let direction: String    // 如"北"
    let centerAngle: Double  // 中心角度
    let startAngle: Double   // 起始角度
    let endAngle: Double     // 结束角度
    let mountains: [String]  // 对应的24山

    /// 八卦完整列表
    static let all: [Trigram] = [
        Trigram(name: "坎", direction: "北",   centerAngle: 0,   startAngle: 337.5, endAngle: 22.5,  mountains: ["子", "癸", "丑"]),
        Trigram(name: "艮", direction: "东北", centerAngle: 45,  startAngle: 22.5,  endAngle: 67.5,  mountains: ["艮", "寅", "甲"]),
        Trigram(name: "震", direction: "东",   centerAngle: 90,  startAngle: 67.5,  endAngle: 112.5, mountains: ["卯", "乙", "辰"]),
        Trigram(name: "巽", direction: "东南", centerAngle: 135, startAngle: 112.5, endAngle: 157.5, mountains: ["巽", "巳", "丙"]),
        Trigram(name: "离", direction: "南",   centerAngle: 180, startAngle: 157.5, endAngle: 202.5, mountains: ["午", "丁", "未"]),
        Trigram(name: "坤", direction: "西南", centerAngle: 225, startAngle: 202.5, endAngle: 247.5, mountains: ["坤", "申", "庚"]),
        Trigram(name: "兑", direction: "西",   centerAngle: 270, startAngle: 247.5, endAngle: 292.5, mountains: ["酉", "辛", "戌"]),
        Trigram(name: "乾", direction: "西北", centerAngle: 315, startAngle: 292.5, endAngle: 337.5, mountains: ["乾", "亥", "壬"]),
    ]

    /// 根据方位角查找对应的卦
    static func fromBearing(_ bearing: Double) -> Trigram {
        // 归一化到0-360
        let normalizedBearing = bearing.truncatingRemainder(dividingBy: 360)
        let positiveBearing = normalizedBearing < 0 ? normalizedBearing + 360 : normalizedBearing

        // 查找对应的卦
        for trigram in all {
            if trigram.startAngle > trigram.endAngle {
                // 跨越0度的情况（如"坎"卦：337.5-22.5）
                if positiveBearing >= trigram.startAngle || positiveBearing < trigram.endAngle {
                    return trigram
                }
            } else {
                // 正常情况
                if positiveBearing >= trigram.startAngle && positiveBearing < trigram.endAngle {
                    return trigram
                }
            }
        }

        // 理论上不会到这里，但为了安全返回"坎"卦
        return all[0]
    }
}
