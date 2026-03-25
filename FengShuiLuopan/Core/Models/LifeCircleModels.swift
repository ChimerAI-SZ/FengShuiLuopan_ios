// LifeCircleModels.swift
// 生活圈数据模型
// 见 PHASE_V4_SPEC.md, ARCHITECTURE.md 10.1节

import Foundation

// MARK: - 生活圈点位类型

/// 生活圈点位类型
enum LifeCirclePointType: String, CaseIterable, Hashable {
    case home           // 家（罗盘最大）
    case work           // 公司（罗盘中等）
    case entertainment  // 日常场所（罗盘最小）

    /// 显示名称
    var displayName: String {
        switch self {
        case .home:          return "家"
        case .work:          return "公司"
        case .entertainment: return "日常场所"
        }
    }

    /// 角色图标
    var icon: String {
        switch self {
        case .home:          return "house.fill"
        case .work:          return "building.2.fill"
        case .entertainment: return "fork.knife"
        }
    }

    /// 罗盘像素尺寸
    /// 见 PHASE_V4_SPEC.md 4.1节
    var compassPixelSize: CGFloat {
        switch self {
        case .home:          return 1200.0  // 最大
        case .work:          return 1000.0  // 中等
        case .entertainment: return 800.0   // 最小
        }
    }

    /// 罗盘地图半径（米）
    var compassRadiusMeters: Double {
        switch self {
        case .home:          return 150.0
        case .work:          return 120.0
        case .entertainment: return 90.0
        }
    }
}

// MARK: - 生活圈数据

/// 生活圈数据
/// 见 ARCHITECTURE.md 10.1节
struct LifeCircleData {
    let homePoint: GeoPoint           // 家（罗盘最大）
    let workPoint: GeoPoint           // 公司（罗盘中等）
    let entertainmentPoint: GeoPoint  // 日常场所（罗盘最小）

    /// 获取所有三点
    var allPoints: [GeoPoint] {
        [homePoint, workPoint, entertainmentPoint]
    }

    /// 根据类型获取点位
    func point(for type: LifeCirclePointType) -> GeoPoint {
        switch type {
        case .home:          return homePoint
        case .work:          return workPoint
        case .entertainment: return entertainmentPoint
        }
    }
}

// MARK: - 生活圈连线

/// 生活圈连线信息
/// 见 ARCHITECTURE.md 10.1节
struct LifeCircleConnection {
    let from: GeoPoint
    let to: GeoPoint
    let distance: Double      // 米
    let bearing: Double       // 0-360°
    let shanName: String      // 24山名称

    /// 格式化距离
    var formattedDistance: String {
        if distance < 1000 {
            return String(format: "%.0f米", distance)
        } else {
            return String(format: "%.2f公里", distance / 1000.0)
        }
    }

    /// 格式化方位角
    var formattedBearing: String {
        return String(format: "%.1f°", bearing)
    }

    /// 生成"指入"标签（显示在接收方罗盘上）
    /// 格式：`→来源名→ | 45.3° | 艮山 | 2.5km`
    var incomingLabel: String {
        return "→\(from.name)→ | \(formattedBearing) | \(shanName) | \(formattedDistance)"
    }
}

// MARK: - 三角连线颜色

/// 生活圈三角连线颜色
/// 见 ARCHITECTURE.md 10.4节
enum LifeCircleConnectionColor {
    /// 家→公司：绿色 #00C853
    static let homeToWork: UInt32 = 0xFF00C853

    /// 公司→餐厅：蓝色 #2196F3
    static let workToEntertainment: UInt32 = 0xFF2196F3

    /// 餐厅→家：橙色 #FF9800
    static let entertainmentToHome: UInt32 = 0xFFFF9800
}

// MARK: - 向导步骤

/// 生活圈激活向导步骤
enum LifeCircleWizardStep {
    case selectingOrigins    // 选择3个原点
    case assigningRoles      // 分配角色
    case active              // 已激活
}
