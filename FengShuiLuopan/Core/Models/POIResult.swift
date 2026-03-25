// POIResult.swift
// POI搜索结果数据模型
// 见 PHASE_V3_SPEC.md

import Foundation

/// POI搜索结果
/// 纯数据模型，无SDK依赖
struct POIResult: Identifiable {
    let id: String
    let name: String
    let address: String
    let coordinate: WGS84Coordinate
    var distance: Double       // 距离起点的距离（米）
    var bearing: Double        // Rhumb Line方位角（0-360°）
    let category: String?      // POI类别

    /// 格式化距离
    var formattedDistance: String {
        if distance < 1000 {
            return String(format: "%.0f米", distance)
        } else {
            return String(format: "%.1fkm", distance / 1000.0)
        }
    }
}
