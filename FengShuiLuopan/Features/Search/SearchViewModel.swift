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
    private var searchTask: Task<Void, Never>?

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

                // 取消旧搜索 Task
                self.searchTask?.cancel()

                if text.trimmingCharacters(in: .whitespaces).isEmpty {
                    self.searchResults = []
                    self.isSearching = false
                } else {
                    self.searchTask = Task {
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
        // 检查 Task 是否已被取消
        guard !Task.isCancelled else { return }

        isSearching = true
        errorMessage = nil

        do {
            let results = try await poiService.searchPOIKeyword(keyword: keyword)

            // 再次检查是否被取消
            guard !Task.isCancelled else { return }

            // 只有当搜索关键词与当前输入一致时才更新结果（避免竞态条件）
            if keyword == searchText.trimmingCharacters(in: .whitespaces) || searchText.contains(keyword) {
                searchResults = results
            }
        } catch {
            // 取消错误不需要显示
            if let poiError = error as? POISearchError, case .cancelled = poiError {
                return
            }
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
