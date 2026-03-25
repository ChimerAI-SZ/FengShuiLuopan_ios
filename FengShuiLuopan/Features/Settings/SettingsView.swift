// SettingsView.swift
// 设置页面（地图SDK选择、区域自动切换）
// 见 PHASE_V5_SPEC.md 3节, ARCHITECTURE.md 4.2.5节

import SwiftUI

/// 设置页面
/// 从主界面右侧"更多"菜单中进入
/// 包含地图SDK选择和区域自动切换设置
/// 见 PHASE_V5_SPEC.md 3.1节
struct SettingsView: View {

    @ObservedObject private var onboardingManager = OnboardingManager.shared
    @Environment(\.dismiss) private var dismiss

    // MARK: - Body

    var body: some View {
        NavigationStack {
            List {
                // 地图SDK选择区块
                mapSDKSection

                // 区域自动切换区块
                crossBorderSection

                // 关于区块
                aboutSection
            }
            .listStyle(.insetGrouped)
            .navigationTitle("设置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
        }
    }

    // MARK: - Sections

    /// 地图SDK选择
    private var mapSDKSection: some View {
        Section {
            ForEach(MapSDKPreference.allCases, id: \.rawValue) { preference in
                Button(action: {
                    onboardingManager.mapSDKPreference = preference
                }) {
                    HStack(spacing: 12) {
                        // 选中状态圆点
                        ZStack {
                            Circle()
                                .strokeBorder(
                                    onboardingManager.mapSDKPreference == preference
                                    ? Color.accentColor : Color.gray.opacity(0.4),
                                    lineWidth: 2
                                )
                                .frame(width: 22, height: 22)

                            if onboardingManager.mapSDKPreference == preference {
                                Circle()
                                    .fill(Color.accentColor)
                                    .frame(width: 12, height: 12)
                            }
                        }

                        VStack(alignment: .leading, spacing: 3) {
                            HStack(spacing: 6) {
                                Text(preference.displayName)
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(.primary)

                                // 推荐标签（自动检测模式）
                                if preference == .auto {
                                    Text("推荐")
                                        .font(.caption2)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color.green)
                                        .cornerRadius(4)
                                }
                            }

                            Text(preference.description)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Spacer()
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        } header: {
            Label("地图SDK选择", systemImage: "map")
        } footer: {
            Text("注：Google Maps功能将在未来版本完整支持，当前选择\"谷歌地图\"时仍使用高德地图。")
                .font(.caption)
        }
    }

    /// 区域自动切换开关
    private var crossBorderSection: some View {
        Section {
            Toggle(isOn: $onboardingManager.autoSwitchOnCrossBorder) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("检测到跨境时自动提示切换")
                        .font(.system(size: 15))
                    Text("当GPS位置检测到您跨越国境时，提示切换地图SDK")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .disabled(onboardingManager.mapSDKPreference != .auto)
        } header: {
            Label("区域自动切换", systemImage: "globe.asia.australia")
        } footer: {
            if onboardingManager.mapSDKPreference != .auto {
                Text("仅在\"自动检测\"模式下可用。")
                    .font(.caption)
            }
        }
    }

    /// 关于信息
    private var aboutSection: some View {
        Section {
            // 版本号
            HStack {
                Label("版本号", systemImage: "info.circle")
                Spacer()
                Text("V\(appVersion)")
                    .foregroundColor(.secondary)
                    .font(.system(size: 15, design: .monospaced))
            }

            // 构建号（可选）
            if let build = buildNumber {
                HStack {
                    Label("构建号", systemImage: "hammer.circle")
                    Spacer()
                    Text(build)
                        .foregroundColor(.secondary)
                        .font(.system(size: 15, design: .monospaced))
                }
            }

            // 技术栈说明
            HStack {
                Label("坐标系统", systemImage: "location.circle")
                Spacer()
                Text("WGS-84 + 恒向线算法")
                    .foregroundColor(.secondary)
                    .font(.caption)
            }

            HStack {
                Label("地图SDK", systemImage: "map.circle")
                Spacer()
                Text("高德地图 9.x")
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
        } header: {
            Label("关于", systemImage: "app.badge")
        }
    }

    // MARK: - Helpers

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "4.0.0"
    }

    private var buildNumber: String? {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String
    }
}

// MARK: - Preview

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
