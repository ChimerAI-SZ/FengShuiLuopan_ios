// SectorSearchView.swift
// 扇形搜索页面
// 见 PHASE_V3_SPEC.md 1.3节

import SwiftUI

/// 扇形搜索Sheet页面
struct SectorSearchView: View {

    @ObservedObject var viewModel: SectorSearchViewModel
    let mapViewModel: MapViewModel
    let poiService: POISearchService

    @Environment(\.dismiss) private var dismiss

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {

                    // 1. 方位模式选择
                    modeSection

                    Divider()

                    // 2. 方向选择器
                    directionSection

                    Divider()

                    // 3. POI关键词
                    poiKeywordSection

                    Divider()

                    // 4. 搜索距离
                    distanceSection

                    Spacer(minLength: 20)
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
            }
            .navigationTitle("选择扇形区域")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        viewModel.cancel()
                        dismiss()
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                bottomButtonBar
            }
        }
    }

    // MARK: - Mode Section

    private var modeSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("方位选择：")
                .font(.headline)

            Picker("方位模式", selection: $viewModel.config.mode) {
                ForEach(SectorMode.allCases, id: \.self) { mode in
                    Text(mode.displayName).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .onChange(of: viewModel.config.mode) { _ in
                viewModel.config.resetDirectionForMode()
            }
        }
    }

    // MARK: - Direction Section

    private var directionSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            let directions = viewModel.config.mode == .shan24
                ? SectorDirection.shan24Directions
                : SectorDirection.bagua8Directions
            let columns = viewModel.config.mode == .shan24 ? 6 : 4
            let gridColumns = Array(repeating: GridItem(.flexible(), spacing: 8), count: columns)

            LazyVGrid(columns: gridColumns, spacing: 8) {
                ForEach(directions, id: \.self) { direction in
                    directionButton(direction)
                }
            }
        }
    }

    private func directionButton(_ direction: SectorDirection) -> some View {
        let isSelected = viewModel.config.direction == direction
        return Button {
            viewModel.config.direction = direction
        } label: {
            Text(direction.displayName)
                .font(viewModel.config.mode == .shan24 ? .caption : .body)
                .fontWeight(isSelected ? .bold : .regular)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(isSelected ? Color.purple : Color(.systemGray5))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(8)
        }
    }

    // MARK: - POI Keyword Section

    private var poiKeywordSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("POI关键词（可选）：")
                .font(.headline)

            TextField("未输入关键词时只绘制扇形区域", text: Binding(
                get: { viewModel.config.poiKeyword ?? "" },
                set: { viewModel.config.poiKeyword = $0.isEmpty ? nil : $0 }
            ))
            .textFieldStyle(.roundedBorder)
            .keyboardType(.default)

            // 快捷关键词
            HStack(spacing: 8) {
                Text("快捷关键词：")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                quickKeywordButton("住宅")
                quickKeywordButton("医院")
                quickKeywordButton("大厦")
            }

            // POI距离警告
            if let warning = viewModel.config.poiDistanceWarning {
                Text(warning)
                    .font(.caption)
                    .foregroundColor(.orange)
            }
        }
    }

    private func quickKeywordButton(_ keyword: String) -> some View {
        Button {
            viewModel.config.poiKeyword = keyword
        } label: {
            Text(keyword)
                .font(.subheadline)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color(.systemGray5))
                .cornerRadius(16)
        }
    }

    // MARK: - Distance Section

    private var distanceSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("搜索距离：")
                .font(.headline)

            // 数字框 + 单位切换
            HStack(spacing: 12) {
                TextField("距离", value: $viewModel.config.distance, format: .number)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.decimalPad)
                    .frame(width: 100)

                Picker("单位", selection: $viewModel.config.distanceUnit) {
                    ForEach(DistanceUnit.allCases, id: \.self) { unit in
                        Text(unit.rawValue).tag(unit)
                    }
                }
                .pickerStyle(.segmented)
            }

            // 距离验证提示
            if let message = viewModel.config.distanceValidationMessage {
                Text(message)
                    .font(.caption)
                    .foregroundColor(.red)
            }

            // 快捷距离
            Text("快捷距离：")
                .font(.subheadline)
                .foregroundColor(.secondary)

            // 第一行：20, 50, 200
            HStack(spacing: 8) {
                quickDistanceButton(value: 20, unit: .kilometer)
                quickDistanceButton(value: 50, unit: .kilometer)
                quickDistanceButton(value: 200, unit: .kilometer)
            }

            // 第二行：1000, 3000, 5000
            HStack(spacing: 8) {
                quickDistanceButton(value: 1000, unit: .kilometer)
                quickDistanceButton(value: 3000, unit: .kilometer)
                quickDistanceButton(value: 5000, unit: .kilometer)
            }
        }
    }

    private func quickDistanceButton(value: Double, unit: DistanceUnit) -> some View {
        let isSelected = viewModel.config.distance == value && viewModel.config.distanceUnit == unit
        let label = unit == .kilometer ? "\(Int(value))km" : "\(Int(value))米"
        return Button {
            viewModel.config.distance = value
            viewModel.config.distanceUnit = unit
        } label: {
            Text(label)
                .font(.subheadline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(isSelected ? Color.purple.opacity(0.2) : Color(.systemGray5))
                .foregroundColor(isSelected ? .purple : .primary)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isSelected ? Color.purple : Color.clear, lineWidth: 1)
                )
        }
    }

    // MARK: - Bottom Button Bar

    private var bottomButtonBar: some View {
        HStack(spacing: 12) {
            // 清除区域按钮（已绘制时显示）
            if viewModel.showClearButton {
                Button {
                    viewModel.clearSector(mapViewModel: mapViewModel)
                    dismiss()
                } label: {
                    Text("清除区域")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color(.systemGray4))
                        .foregroundColor(.primary)
                        .cornerRadius(12)
                }
            }

            // 主操作按钮
            Button {
                Task {
                    await viewModel.apply(mapViewModel: mapViewModel, poiService: poiService)
                    await MainActor.run {
                        // 只在没有错误时才关闭 Sheet
                        if viewModel.searchResultMessage == nil || !viewModel.searchResultMessage!.contains("搜索失败") {
                            dismiss()
                        }
                    }
                }
            } label: {
                if viewModel.isSearching {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.purple)
                        .cornerRadius(12)
                } else {
                    Text(viewModel.actionButtonTitle)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(viewModel.canPerformAction ? Color.purple : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
            }
            .disabled(!viewModel.canPerformAction || viewModel.isSearching)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
    }
}
