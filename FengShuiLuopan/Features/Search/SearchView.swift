// SearchView.swift
// 搜索Tab页面
// 见 PHASE_V3_SPEC.md 2.1节

import SwiftUI

/// 搜索Tab页面
struct SearchView: View {

    @ObservedObject var viewModel: SearchViewModel
    let mapViewModel: MapViewModel
    let onSelectPOI: (POIResult) -> Void

    @FocusState private var isSearchFocused: Bool

    // MARK: - Body

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 搜索框
                searchBar

                Divider()

                // 搜索结果列表
                if viewModel.searchResults.isEmpty && viewModel.searchText.isEmpty {
                    emptyState
                } else if viewModel.searchResults.isEmpty {
                    noResultsState
                } else {
                    resultsList
                }

                Spacer()
            }
            .navigationTitle("搜索")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)

            TextField("搜索POI", text: $viewModel.searchText)
                .focused($isSearchFocused)
                .textFieldStyle(.plain)
                .keyboardType(.default)

            if !viewModel.searchText.isEmpty {
                Button {
                    viewModel.clearSearch()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color(.systemGray6))
        .cornerRadius(8)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(.gray)

            Text("搜索POI")
                .font(.headline)
                .foregroundColor(.secondary)

            Text("输入关键词搜索周边地点")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }

    // MARK: - No Results State

    private var noResultsState: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(.gray)

            Text("未找到结果")
                .font(.headline)
                .foregroundColor(.secondary)

            if let error = viewModel.errorMessage {
                Text(error)
                    .font(.subheadline)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
            } else {
                Text("未找到与\"\(viewModel.searchText)\"相关的地点")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }

    // MARK: - Results List

    private var resultsList: some View {
        List {
            if viewModel.isSearching {
                HStack {
                    ProgressView()
                        .progressViewStyle(.circular)
                    Text("搜索中...")
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .listRowInsets(EdgeInsets())
            }

            ForEach(viewModel.searchResults, id: \.id) { poi in
                poiResultRow(poi)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        onSelectPOI(poi)
                    }
            }
        }
        .listStyle(.plain)
    }

    private func poiResultRow(_ poi: POIResult) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Image(systemName: "mappin.circle.fill")
                    .foregroundColor(.purple)
                    .font(.system(size: 16))

                VStack(alignment: .leading, spacing: 2) {
                    Text(poi.name)
                        .font(.headline)
                        .lineLimit(1)

                    Text(poi.address)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text(poi.formattedDistance)
                        .font(.caption)
                        .foregroundColor(.secondary)

                    if let category = poi.category {
                        Text(category)
                            .font(.caption2)
                            .foregroundColor(.gray)
                            .lineLimit(1)
                    }
                }
            }
        }
        .padding(.vertical, 8)
    }
}
