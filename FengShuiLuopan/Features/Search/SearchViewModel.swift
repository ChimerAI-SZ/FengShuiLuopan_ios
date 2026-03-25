// SearchViewModel.swift
// 搜索Tab视图模型
// 见 PHASE_V3_SPEC.md 2节

import Foundation
import Combine

/// 搜索Tab视图模型
class SearchViewModel: ObservableObject {

    // MARK: - Published Properties

    /// 搜索关键词
    @Published var searchText: String = ""

    /// 搜索结果
    @Published var searchResults: [POIResult] = []

    /// 是否正在搜索
    @Published var isSearching: Bool = false

    /// 错误消息
    @Published var errorMessage: String?

    // MARK: - Private Properties

    private let poiService: POISearchService
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    init(poiService: POISearchService) {
        self.poiService = poiService
        setupSearchDebounce()
    }

    // MARK: - Setup

    /// 设置搜索防抖（300ms）
    private func setupSearchDebounce() {
        $searchText
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .removeDuplicates()
            .sink { [weak self] text in
                guard let self = self else { return }
                if text.trimmingCharacters(in: .whitespaces).isEmpty {
                    self.searchResults = []
                    self.isSearching = false
                } else {
                    Task {
                        await self.performSearch(keyword: text)
                    }
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - Search

    /// 执行搜索
    /// - Parameter keyword: 搜索关键词
    @MainActor
    private func performSearch(keyword: String) async {
        isSearching = true
        errorMessage = nil

        do {
            let results = try await poiService.searchPOIKeyword(keyword: keyword)
            // 只有当搜索关键词与当前输入一致时才更新结果（避免竞态条件）
            if keyword == searchText.trimmingCharacters(in: .whitespaces) || searchText.contains(keyword) {
                searchResults = results
            }
        } catch {
            errorMessage = "搜索失败：\(error.localizedDescription)"
            searchResults = []
        }

        isSearching = false
    }

    /// 清除搜索
    func clearSearch() {
        searchText = ""
        searchResults = []
        errorMessage = nil
    }
}
