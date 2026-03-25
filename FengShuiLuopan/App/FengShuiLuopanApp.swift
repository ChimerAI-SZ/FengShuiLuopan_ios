// FengShuiLuopanApp.swift
// 应用入口
// 见 ARCHITECTURE.md 5节, PHASE_V2_SPEC.md, PHASE_V5_SPEC.md

import SwiftUI

@main
struct FengShuiLuopanApp: App {

    /// 驱动根视图切换的状态（false=显示新手指导，true=进入主界面）
    @State private var onboardingCompleted: Bool = !OnboardingManager.shared.shouldShowOnboarding()

    var body: some Scene {
        WindowGroup {
            if onboardingCompleted {
                // 正常主界面
                MainContentView()
            } else {
                // 首次启动或版本更新后显示新手指导
                OnboardingView {
                    withAnimation(.easeInOut(duration: 0.4)) {
                        onboardingCompleted = true
                    }
                }
            }
        }
    }
}
