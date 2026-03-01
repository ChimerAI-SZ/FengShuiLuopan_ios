// MainContentView.swift
// 主内容视图（带底部Tab栏）
// 见 PHASE_V2_SPEC.md

import SwiftUI

/// 主内容视图
struct MainContentView: View {

    @State private var selectedTab: Tab = .map

    enum Tab {
        case map
        case caseManagement
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            // 地图页面
            MapView()
                .tabItem {
                    Label("地图", systemImage: "map")
                }
                .tag(Tab.map)

            // 堪舆管理页面
            CaseManagementView()
                .tabItem {
                    Label("堪舆管理", systemImage: "folder")
                }
                .tag(Tab.caseManagement)
        }
    }
}
