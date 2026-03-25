// HelpView.swift
// 使用说明页面（第4个Tab）
// 见 PHASE_V5_SPEC.md 2节

import SwiftUI

/// 使用说明页面
/// 包含基础功能说明、高级功能说明、常见问题、版本信息
/// 底部有"重置新手指导"按钮
/// 见 PHASE_V5_SPEC.md 2节
struct HelpView: View {

    @StateObject private var onboardingManager = OnboardingManager.shared

    /// 是否显示重置成功提示
    @State private var showResetConfirm: Bool = false

    /// 当前 App 版本号
    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "4.0.0"
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            List {
                // 基础功能区块
                basicSection

                // 高级功能区块
                advancedSection

                // 常见问题区块
                faqSection

                // 版本信息 + 重置按钮
                footerSection
            }
            .listStyle(.insetGrouped)
            .navigationTitle("使用说明")
        }
        // 重置成功提示（Toast）
        .overlay(alignment: .bottom) {
            if showResetConfirm {
                Text("✅ 新手指导已重置，下次启动时将重新显示")
                    .font(.caption)
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.black.opacity(0.75))
                    .cornerRadius(10)
                    .padding(.bottom, 40)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                            withAnimation { showResetConfirm = false }
                        }
                    }
            }
        }
        .animation(.easeInOut(duration: 0.3), value: showResetConfirm)
    }

    // MARK: - Sections

    /// 基础功能说明
    private var basicSection: some View {
        Section {
            helpRow(
                icon: "map",
                iconColor: .blue,
                title: "地图操作",
                detail: "双指缩放地图；屏幕中心十字为当前选点；右侧+/-按钮快速缩放；地图类型按钮切换卫星/标准视图"
            )
            helpRow(
                icon: "mappin.and.ellipse",
                iconColor: .red,
                title: "添加原点和终点",
                detail: "点击右侧"+"按钮添加原点（红色图钉）或终点（蓝色图钉）；原点为罗盘中心，终点为测量目标"
            )
            helpRow(
                icon: "arrow.triangle.2.circlepath",
                iconColor: .orange,
                title: "查看连线信息",
                detail: "添加终点后自动显示连线，包含：方位角（°）、24山卦位、Vincenty距离"
            )
            helpRow(
                icon: "lock.circle",
                iconColor: .purple,
                title: "罗盘锁定/解锁模式",
                detail: "点击右侧锁定按钮：锁定模式—罗盘随地图旋转；解锁模式—罗盘固定在屏幕中心叠加显示"
            )
            helpRow(
                icon: "location.fill",
                iconColor: .green,
                title: "GPS定位",
                detail: "点击右侧绿色定位按钮，地图自动移动到当前GPS位置"
            )
        } header: {
            Label("基础功能", systemImage: "star.fill")
        }
    }

    /// 高级功能说明
    private var advancedSection: some View {
        Section {
            helpRow(
                icon: "folder.badge.plus",
                iconColor: .indigo,
                title: "案例管理",
                detail: "底部\"堪舆管理\"Tab创建和管理多个案例；每个案例独立存储原点和终点；支持多项目并行跟踪"
            )
            helpRow(
                icon: "person.2",
                iconColor: .indigo,
                title: "多原点多终点",
                detail: "每个案例支持2个原点（含GPS自动原点）；每个原点支持5个终点；可同时展示多条测量连线"
            )
            helpRow(
                icon: "circle.dashed",
                iconColor: .purple,
                title: "扇形搜索",
                detail: "点击右侧扇形按钮，设置方位角和半径，在指定方位扇区内搜索周边POI"
            )
            helpRow(
                icon: "magnifyingglass.circle",
                iconColor: .blue,
                title: "POI搜索",
                detail: "底部\"搜索\"Tab可按关键词搜索周边兴趣点，支持按24山方位过滤结果"
            )
            helpRow(
                icon: "scope",
                iconColor: .teal,
                title: "十字准心选点",
                detail: "在搜索结果中点击\"在地图标记\"，进入十字准心模式，滑动地图精准定位并保存为原点或终点"
            )
            helpRow(
                icon: "house.circle",
                iconColor: .purple,
                title: "生活圈模式",
                detail: "点击右侧\"…\"更多菜单，选择\"生活圈模式\"；选择3个原点分别代表家/公司/日常场所，自动绘制三角连线"
            )
        } header: {
            Label("高级功能", systemImage: "wand.and.stars")
        }
    }

    /// 常见问题
    private var faqSection: some View {
        Section {
            faqRow(
                question: "如何添加多个原点？",
                answer: "在\"堪舆管理\"中切换到对应案例，然后点击地图右侧红色图钉按钮（原点按钮），可添加第2个原点。每个案例最多支持2个用户自定义原点（另有1个GPS自动原点）。"
            )
            faqRow(
                question: "什么是24山？",
                answer: "24山是中国传统罗盘将360°方位分为24等份的方位系统，每山15°。包括：子、癸、丑、艮、寅、甲、卯、乙、辰、巽、巳、丙、午、丁、未、坤、申、庚、酉、辛、戌、乾、亥、壬。"
            )
            faqRow(
                question: "如何使用扇形搜索？",
                answer: "点击右侧紫色圆形虚线按钮，在弹出界面选择：1）搜索方位（24山或八方位）；2）搜索半径；3）POI类型关键词。点击搜索后，扇形区域内的结果会显示在列表中。"
            )
            faqRow(
                question: "生活圈模式是什么？",
                answer: "生活圈模式将家、公司、日常场所（如餐厅/商场）三个地点建立风水三角关系，分别显示不同大小的罗盘，并绘制三角连线，分析三地之间的方位关系。"
            )
            faqRow(
                question: "为什么需要GPS权限？",
                answer: "GPS权限用于：1）将您的当前位置显示为GPS自动原点；2）在生活圈模式中快速定位；3）扇形搜索时以当前位置为中心。不授权时仍可手动添加坐标点使用所有功能。"
            )
            faqRow(
                question: "方位角为什么用恒向线（Rhumb Line）？",
                answer: "恒向线具有角度对称性：A→B和B→A的方位角之差精确为180°，原点终点互换后山位索引差恰好12山，与罗盘设计完全吻合。这是与传统Flutter版的有意改进。"
            )
        } header: {
            Label("常见问题", systemImage: "questionmark.circle")
        }
    }

    /// 版本信息 + 重置新手指导
    private var footerSection: some View {
        Section {
            // 版本号
            HStack {
                Label("当前版本", systemImage: "info.circle")
                Spacer()
                Text("V\(appVersion)")
                    .foregroundColor(.secondary)
                    .font(.system(size: 15, design: .monospaced))
            }

            // 重置新手指导按钮
            Button(action: {
                onboardingManager.resetOnboarding()
                withAnimation { showResetConfirm = true }
            }) {
                HStack {
                    Label("重置新手指导", systemImage: "arrow.counterclockwise.circle")
                        .foregroundColor(.orange)
                    Spacer()
                    Text("下次启动重新引导")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        } header: {
            Label("关于", systemImage: "app.badge")
        }
    }

    // MARK: - Row Builders

    /// 帮助内容行（图标 + 标题 + 折叠详情）
    private func helpRow(
        icon: String,
        iconColor: Color,
        title: String,
        detail: String
    ) -> some View {
        DisclosureGroup {
            Text(detail)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .lineSpacing(4)
                .padding(.vertical, 4)
        } label: {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .foregroundColor(iconColor)
                    .frame(width: 22)
                Text(title)
                    .font(.system(size: 15, weight: .medium))
            }
        }
    }

    /// 常见问题行（折叠式）
    private func faqRow(question: String, answer: String) -> some View {
        DisclosureGroup {
            Text(answer)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .lineSpacing(4)
                .padding(.vertical, 4)
        } label: {
            Text(question)
                .font(.system(size: 15))
        }
    }
}

// MARK: - Preview

struct HelpView_Previews: PreviewProvider {
    static var previews: some View {
        HelpView()
    }
}
