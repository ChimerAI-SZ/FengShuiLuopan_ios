// OnboardingManager.swift
// 新手指导管理器 + 应用设置管理器
// 见 PHASE_V5_SPEC.md 1节, ARCHITECTURE.md 4.2.5节

import Foundation
import Combine

// MARK: - OnboardingManager

/// 新手指导管理器
/// 基于 UserDefaults 判断是否需要显示新手指导
/// 见 PHASE_V5_SPEC.md 1节
class OnboardingManager: ObservableObject {

    // MARK: - Keys

    private enum Keys {
        static let onboardingVersion    = "onboarding_completed_version"
        static let mapSDKPreference     = "map_sdk_preference"
        static let autoSwitchCrossBorder = "auto_switch_cross_border"
    }

    // MARK: - Current Version

    /// 当前指导版本（版本更新时可触发重新引导）
    private let currentVersion = "4.0.0"

    // MARK: - Singleton

    static let shared = OnboardingManager()

    // MARK: - Published Settings

    /// 地图SDK偏好
    @Published var mapSDKPreference: MapSDKPreference {
        didSet {
            UserDefaults.standard.set(mapSDKPreference.rawValue, forKey: Keys.mapSDKPreference)
        }
    }

    /// 跨境时是否自动提示切换
    @Published var autoSwitchOnCrossBorder: Bool {
        didSet {
            UserDefaults.standard.set(autoSwitchOnCrossBorder, forKey: Keys.autoSwitchCrossBorder)
        }
    }

    // MARK: - Init

    private init() {
        // 读取 mapSDKPreference
        let rawSDK = UserDefaults.standard.integer(forKey: Keys.mapSDKPreference)
        self.mapSDKPreference = MapSDKPreference(rawValue: rawSDK) ?? .auto

        // 读取 autoSwitchOnCrossBorder（默认 true）
        if UserDefaults.standard.object(forKey: Keys.autoSwitchCrossBorder) != nil {
            self.autoSwitchOnCrossBorder = UserDefaults.standard.bool(forKey: Keys.autoSwitchCrossBorder)
        } else {
            self.autoSwitchOnCrossBorder = true
        }
    }

    // MARK: - Onboarding Control

    /// 是否需要显示新手指导
    /// 条件：UserDefaults中保存的版本号与当前版本不匹配
    func shouldShowOnboarding() -> Bool {
        let completed = UserDefaults.standard.string(forKey: Keys.onboardingVersion)
        return completed != currentVersion
    }

    /// 标记新手指导已完成（当前版本）
    func markOnboardingCompleted() {
        UserDefaults.standard.set(currentVersion, forKey: Keys.onboardingVersion)
    }

    /// 重置新手指导（下次启动重新显示）
    /// 见 PHASE_V5_SPEC.md 1.4节
    func resetOnboarding() {
        UserDefaults.standard.removeObject(forKey: Keys.onboardingVersion)
    }

    // MARK: - Cross-Border Detection (简化版)
    // 见 PHASE_V5_SPEC.md 3.3节，ARCHITECTURE.md 4.2.5节
    // 完整实现推迟到 V5，此处仅提供框架

    /// 简化版跨境检测（仅基于经纬度判断国内/国外）
    func detectRegion(latitude: Double, longitude: Double) -> String {
        let isInChina = (
            latitude  >= 18.0 && latitude  <= 54.0 &&
            longitude >= 73.0 && longitude <= 135.0
        )
        return isInChina ? "CN" : "OTHER"
    }

    /// 选择最合适的地图SDK（简化版，V5完整实现）
    func selectSDKType(latitude: Double, longitude: Double) -> MapSDKType {
        switch mapSDKPreference {
        case .auto:
            let region = detectRegion(latitude: latitude, longitude: longitude)
            return region == "CN" ? .gaode : .google
        case .amap:
            return .gaode
        case .google:
            return .google
        }
    }
}
