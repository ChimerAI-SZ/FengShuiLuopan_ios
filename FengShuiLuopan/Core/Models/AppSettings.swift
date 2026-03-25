// AppSettings.swift
// 应用设置数据模型
// 见 PHASE_V5_SPEC.md, ARCHITECTURE.md 4.2.4节

import Foundation

// MARK: - MapSDKPreference

/// 地图SDK偏好设置
enum MapSDKPreference: Int, CaseIterable {
    case auto   = 0 // 自动检测（根据GPS/SIM卡选择最佳SDK）
    case amap   = 1 // 强制高德地图
    case google = 2 // 强制Google Maps

    var displayName: String {
        switch self {
        case .auto:   return "自动检测"
        case .amap:   return "高德地图"
        case .google: return "谷歌地图"
        }
    }

    var description: String {
        switch self {
        case .auto:
            return "根据GPS位置自动选择最佳SDK"
        case .amap:
            return "适用于中国大陆用户"
        case .google:
            return "适用于海外用户或有VPN的用户"
        }
    }
}

// MARK: - AppSettings

/// 应用全局设置
/// 通过 UserDefaults 持久化
struct AppSettings {
    var mapSDKPreference: MapSDKPreference
    var autoSwitchOnCrossBorder: Bool
    var hasCompletedOnboarding: Bool
    var onboardingVersion: String

    static let `default` = AppSettings(
        mapSDKPreference: .auto,
        autoSwitchOnCrossBorder: true,
        hasCompletedOnboarding: false,
        onboardingVersion: ""
    )
}

// MARK: - OnboardingStep

/// 新手指导步骤数据
struct OnboardingStep: Identifiable {
    let id: Int
    let title: String
    let description: String
    let iconName: String       // SF Symbol 名称
    let imageName: String?     // 可选图片资源（如截图）

    /// 六个指导步骤（见 PHASE_V5_SPEC.md 1.2节）
    static let allSteps: [OnboardingStep] = [
        OnboardingStep(
            id: 0,
            title: "欢迎使用堪舆罗盘",
            description: "基于24山的专业风水方位测量工具\n精准计算方位角、距离与24山卦位",
            iconName: "arrow.triangle.2.circlepath.circle.fill",
            imageName: nil
        ),
        OnboardingStep(
            id: 1,
            title: "GPS权限说明",
            description: "应用需要获取您的位置信息\n用于显示GPS原点罗盘和精准测量方位\n请在弹出权限请求时选择\"允许\"",
            iconName: "location.circle.fill",
            imageName: nil
        ),
        OnboardingStep(
            id: 2,
            title: "地图基础操作",
            description: "• 双指捏合缩放地图\n• 屏幕中心十字指示当前选点位置\n• 右上角可切换卫星/标准地图\n• 右侧按钮快速放大缩小",
            iconName: "map.circle.fill",
            imageName: nil
        ),
        OnboardingStep(
            id: 3,
            title: "添加原点与终点",
            description: "• 点击右侧\"+\"按钮，选择添加原点或终点\n• 原点为罗盘中心，显示24山罗盘\n• 终点为测量目标，自动显示连线信息\n• 每条连线显示：方位角、24山、距离",
            iconName: "mappin.and.ellipse",
            imageName: nil
        ),
        OnboardingStep(
            id: 4,
            title: "案例管理",
            description: "• 底部\"堪舆管理\"Tab管理多个案例\n• 每个案例可独立管理原点和终点\n• 支持对多个风水项目同时跟踪\n• 扇形搜索可在指定方位查找POI",
            iconName: "folder.circle.fill",
            imageName: nil
        ),
        OnboardingStep(
            id: 5,
            title: "开始使用",
            description: "一切就绪！\n\n您可以在\"说明\"Tab中随时查看\n完整的使用指南和常见问题解答",
            iconName: "checkmark.circle.fill",
            imageName: nil
        )
    ]
}
