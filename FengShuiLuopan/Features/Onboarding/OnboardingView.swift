// OnboardingView.swift
// 新手指导页面（6步引导）
// 见 PHASE_V5_SPEC.md 1节

import SwiftUI

/// 新手指导主视图
/// 首次启动应用时显示，可逐步查看或跳过
/// 见 PHASE_V5_SPEC.md 1.3节
struct OnboardingView: View {

    /// 完成回调（指导完成或跳过后调用）
    let onComplete: () -> Void

    @State private var currentStep: Int = 0

    private let steps = OnboardingStep.allSteps

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {

            // 内容区域（可滑动切换页面）
            TabView(selection: $currentStep) {
                ForEach(steps) { step in
                    OnboardingStepView(step: step)
                        .tag(step.id)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut, value: currentStep)

            // 进度指示器
            progressIndicator
                .padding(.vertical, 20)

            // 底部按钮区
            bottomButtons
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
        }
        .background(Color(.systemBackground))
    }

    // MARK: - Subviews

    /// 步骤进度点
    private var progressIndicator: some View {
        HStack(spacing: 8) {
            ForEach(steps.indices, id: \.self) { index in
                Circle()
                    .fill(index == currentStep
                          ? Color.accentColor
                          : Color.gray.opacity(0.3))
                    .frame(width: index == currentStep ? 10 : 7,
                           height: index == currentStep ? 10 : 7)
                    .animation(.easeInOut(duration: 0.2), value: currentStep)
            }
        }
    }

    /// 底部按钮：跳过 / 下一步（或"开始使用"）
    private var bottomButtons: some View {
        HStack {
            // 跳过按钮（最后一步隐藏）
            if currentStep < steps.count - 1 {
                Button(action: completeOnboarding) {
                    Text("跳过")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                        .padding(.vertical, 14)
                        .padding(.horizontal, 20)
                }
            } else {
                // 占位（保持布局对称）
                Spacer()
                    .frame(width: 80)
            }

            Spacer()

            // 下一步 / 开始使用
            Button(action: handleNextTap) {
                HStack(spacing: 6) {
                    Text(currentStep < steps.count - 1 ? "下一步" : "开始使用")
                        .font(.system(size: 16, weight: .semibold))
                    if currentStep < steps.count - 1 {
                        Image(systemName: "arrow.right")
                            .font(.system(size: 14, weight: .semibold))
                    }
                }
                .foregroundColor(.white)
                .padding(.vertical, 14)
                .padding(.horizontal, 28)
                .background(
                    currentStep < steps.count - 1
                    ? Color.accentColor
                    : Color.green
                )
                .cornerRadius(25)
            }
        }
    }

    // MARK: - Actions

    private func handleNextTap() {
        if currentStep < steps.count - 1 {
            withAnimation {
                currentStep += 1
            }
        } else {
            completeOnboarding()
        }
    }

    private func completeOnboarding() {
        OnboardingManager.shared.markOnboardingCompleted()
        onComplete()
    }
}

// MARK: - OnboardingStepView

/// 单个指导步骤视图
private struct OnboardingStepView: View {

    let step: OnboardingStep

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // 图标（大尺寸 SF Symbol）
            Image(systemName: step.iconName)
                .font(.system(size: 80, weight: .light))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.accentColor, .accentColor.opacity(0.6)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .padding(.bottom, 8)

            // 标题
            Text(step.title)
                .font(.system(size: 26, weight: .bold))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            // 描述
            Text(step.description)
                .font(.system(size: 16))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .lineSpacing(6)
                .padding(.horizontal, 36)

            Spacer()
            Spacer()
        }
    }
}

// MARK: - Preview

struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView(onComplete: {})
    }
}
