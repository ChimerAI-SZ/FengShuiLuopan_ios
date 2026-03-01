// ConnectionColorHelper.swift
// 连线颜色辅助类
// 见 ARCHITECTURE.md 第8节, PHASE_V2_SPEC.md

import UIKit

/// 连线颜色辅助类
struct ConnectionColorHelper {

    /// 连线颜色方案（见ARCHITECTURE.md 第8节）
    private static let colors: [UIColor] = [
        UIColor(hex: "#2196F3"),  // 蓝色
        UIColor(hex: "#4CAF50"),  // 绿色
        UIColor(hex: "#FF9800"),  // 橙色
        UIColor(hex: "#9C27B0"),  // 紫色
        UIColor(hex: "#F44336")   // 红色
    ]

    /// 获取终点的连线颜色
    /// - Parameters:
    ///   - destination: 终点
    ///   - destinations: 所有终点列表（按创建时间排序）
    /// - Returns: 对应的颜色
    static func getColor(for destination: GeoPoint, in destinations: [GeoPoint]) -> UIColor {
        guard let index = destinations.firstIndex(where: { $0.id == destination.id }) else {
            return colors[0]  // 默认蓝色
        }

        return colors[index % colors.count]
    }

    /// 获取指定索引的颜色
    static func getColor(at index: Int) -> UIColor {
        return colors[index % colors.count]
    }
}

// MARK: - UIColor Extension

extension UIColor {
    /// 从十六进制字符串创建UIColor
    convenience init(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0
        Scanner(string: hexSanitized).scanHexInt64(&rgb)

        let red = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
        let green = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
        let blue = CGFloat(rgb & 0x0000FF) / 255.0

        self.init(red: red, green: green, blue: blue, alpha: 1.0)
    }
}
