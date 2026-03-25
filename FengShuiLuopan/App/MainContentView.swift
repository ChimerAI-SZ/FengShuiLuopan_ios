// MainContentView.swift
// 主内容视图（带底部Tab栏）
// 见 PHASE_V2_SPEC.md, PHASE_V3_SPEC.md, PHASE_V5_SPEC.md

import SwiftUI

/// 主内容视图
struct MainContentView: View {

    @StateObject private var mapViewModel = MapViewModel()
    @StateObject private var searchViewModel: SearchViewModel
    @State private var selectedTab: Tab = .map

    init() {
        let mapVM = MapViewModel()
        _mapViewModel = StateObject(wrappedValue: mapVM)
        _searchViewModel = StateObject(wrappedValue: SearchViewModel(poiService: mapVM.poiSearchService))
    }

    enum Tab {
        case map
        case caseManagement
        case search
        case help          // Phase 5: 使用说明
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            // 地图页面
            MapView(viewModel: mapViewModel)
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

            // 搜索页面（Phase 3）
            SearchView(
                viewModel: searchViewModel,
                mapViewModel: mapViewModel,
                onSelectPOI: { poi in
                    mapViewModel.enterCrosshairMode(poi: poi)
                    selectedTab = .map
                }
            )
            .tabItem {
                Label("搜索", systemImage: "magnifyingglass")
            }
            .tag(Tab.search)

            // 使用说明页面（Phase 5）
            HelpView()
                .tabItem {
                    Label("说明", systemImage: "questionmark.circle")
                }
                .tag(Tab.help)
        }
    }
}
