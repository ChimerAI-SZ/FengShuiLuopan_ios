// Mountain.swift
// 24山数据模型
// 见ARCHITECTURE.md 3.1节

import Foundation

/// 24山（罗盘方位）
struct Mountain {
    let index: Int           // 0-23
    let name: String         // 如"子"
    let centerAngle: Double  // 中心角度（0-360）
    let startAngle: Double   // 起始角度
    let endAngle: Double     // 结束角度

    /// 24山完整列表（从正北0°开始，顺时针）
    static let all: [Mountain] = [
        Mountain(index: 0,  name: "子", centerAngle: 0,    startAngle: 352.5, endAngle: 7.5),
        Mountain(index: 1,  name: "癸", centerAngle: 15,   startAngle: 7.5,   endAngle: 22.5),
        Mountain(index: 2,  name: "丑", centerAngle: 30,   startAngle: 22.5,  endAngle: 37.5),
        Mountain(index: 3,  name: "艮", centerAngle: 45,   startAngle: 37.5,  endAngle: 52.5),
        Mountain(index: 4,  name: "寅", centerAngle: 60,   startAngle: 52.5,  endAngle: 67.5),
        Mountain(index: 5,  name: "甲", centerAngle: 75,   startAngle: 67.5,  endAngle: 82.5),
        Mountain(index: 6,  name: "卯", centerAngle: 90,   startAngle: 82.5,  endAngle: 97.5),
        Mountain(index: 7,  name: "乙", centerAngle: 105,  startAngle: 97.5,  endAngle: 112.5),
        Mountain(index: 8,  name: "辰", centerAngle: 120,  startAngle: 112.5, endAngle: 127.5),
        Mountain(index: 9,  name: "巽", centerAngle: 135,  startAngle: 127.5, endAngle: 142.5),
        Mountain(index: 10, name: "巳", centerAngle: 150,  startAngle: 142.5, endAngle: 157.5),
        Mountain(index: 11, name: "丙", centerAngle: 165,  startAngle: 157.5, endAngle: 172.5),
        Mountain(index: 12, name: "午", centerAngle: 180,  startAngle: 172.5, endAngle: 187.5),
        Mountain(index: 13, name: "丁", centerAngle: 195,  startAngle: 187.5, endAngle: 202.5),
        Mountain(index: 14, name: "未", centerAngle: 210,  startAngle: 202.5, endAngle: 217.5),
        Mountain(index: 15, name: "坤", centerAngle: 225,  startAngle: 217.5, endAngle: 232.5),
        Mountain(index: 16, name: "申", centerAngle: 240,  startAngle: 232.5, endAngle: 247.5),
        Mountain(index: 17, name: "庚", centerAngle: 255,  startAngle: 247.5, endAngle: 262.5),
        Mountain(index: 18, name: "酉", centerAngle: 270,  startAngle: 262.5, endAngle: 277.5),
        Mountain(index: 19, name: "辛", centerAngle: 285,  startAngle: 277.5, endAngle: 292.5),
        Mountain(index: 20, name: "戌", centerAngle: 300,  startAngle: 292.5, endAngle: 307.5),
        Mountain(index: 21, name: "乾", centerAngle: 315,  startAngle: 307.5, endAngle: 322.5),
        Mountain(index: 22, name: "亥", centerAngle: 330,  startAngle: 322.5, endAngle: 337.5),
        Mountain(index: 23, name: "壬", centerAngle: 345,  startAngle: 337.5, endAngle: 352.5),
    ]

    /// 根据方位角查找对应的山
    static func fromBearing(_ bearing: Double) -> Mountain {
        // 归一化到0-360
        let normalizedBearing = bearing.truncatingRemainder(dividingBy: 360)
        let positiveBearing = normalizedBearing < 0 ? normalizedBearing + 360 : normalizedBearing

        // 查找对应的山
        for mountain in all {
            if mountain.startAngle > mountain.endAngle {
                // 跨越0度的情况（如"子"山：352.5-7.5）
                if positiveBearing >= mountain.startAngle || positiveBearing < mountain.endAngle {
                    return mountain
                }
            } else {
                // 正常情况
                if positiveBearing >= mountain.startAngle && positiveBearing < mountain.endAngle {
                    return mountain
                }
            }
        }

        // 理论上不会到这里，但为了安全返回"子"山
        return all[0]
    }
}
