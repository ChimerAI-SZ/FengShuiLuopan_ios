// CaseManagementView.swift
// 案例管理视图
// 见 PHASE_V2_SPEC.md

import SwiftUI

/// 案例管理视图
struct CaseManagementView: View {

    @StateObject private var viewModel = CaseManagementViewModel()

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 搜索栏和添加按钮
                HStack {
                    // 搜索栏
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                        TextField("搜索案例", text: $viewModel.searchKeyword)
                    }
                    .padding(8)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)

                    // 添加按钮
                    Button(action: {
                        viewModel.showCreateCaseDialog = true
                    }) {
                        Image(systemName: "plus")
                            .font(.system(size: 20))
                            .foregroundColor(.blue)
                    }
                }
                .padding()

                // 案例列表
                if viewModel.cases.isEmpty {
                    Spacer()
                    Text("暂无案例")
                        .foregroundColor(.gray)
                    Spacer()
                } else {
                    List {
                        ForEach(viewModel.cases) { fengShuiCase in
                            CaseRow(
                                fengShuiCase: fengShuiCase,
                                isExpanded: viewModel.expandedCaseIds.contains(fengShuiCase.id),
                                points: viewModel.casePoints[fengShuiCase.id] ?? [],
                                onToggleExpansion: {
                                    viewModel.toggleCaseExpansion(fengShuiCase.id)
                                },
                                onDeleteCase: {
                                    viewModel.deleteCase(fengShuiCase.id)
                                },
                                onDeletePoint: { pointId in
                                    viewModel.deletePoint(pointId, from: fengShuiCase.id)
                                },
                                onUpdatePointName: { point, newName in
                                    viewModel.updatePointName(point, newName: newName)
                                }
                            )
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("堪舆管理")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $viewModel.showCreateCaseDialog) {
                CreateCaseDialog(onCreate: { name, description in
                    viewModel.createCase(name: name, description: description)
                })
            }
            .alert("错误", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("确定") {
                    viewModel.clearError()
                }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
    }
}

// MARK: - Case Row

/// 案例行
struct CaseRow: View {

    let fengShuiCase: FengShuiCase
    let isExpanded: Bool
    let points: [GeoPoint]
    let onToggleExpansion: () -> Void
    let onDeleteCase: () -> Void
    let onDeletePoint: (Int) -> Void
    let onUpdatePointName: (GeoPoint, String) -> Void

    @State private var showEditDialog = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 案例头部
            HStack {
                // 展开/折叠按钮
                Button(action: onToggleExpansion) {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .foregroundColor(.gray)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(fengShuiCase.name)
                        .font(.headline)

                    if let description = fengShuiCase.description, !description.isEmpty {
                        Text(description)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                }

                Spacer()

                // 编辑按钮
                Button(action: {
                    showEditDialog = true
                }) {
                    Image(systemName: "pencil")
                        .foregroundColor(.blue)
                }
            }

            // 展开的点位列表
            if isExpanded {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(points) { point in
                        PointRow(
                            point: point,
                            onDelete: {
                                onDeletePoint(point.id)
                            },
                            onUpdateName: { newName in
                                onUpdatePointName(point, newName)
                            }
                        )
                    }

                    if points.isEmpty {
                        Text("暂无点位")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .padding(.leading, 24)
                    }
                }
                .padding(.leading, 24)
            }
        }
        .padding(.vertical, 8)
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive, action: onDeleteCase) {
                Label("删除", systemImage: "trash")
            }
        }
    }
}

// MARK: - Point Row

/// 点位行
struct PointRow: View {

    let point: GeoPoint
    let onDelete: () -> Void
    let onUpdateName: (String) -> Void

    @State private var showEditDialog = false

    var body: some View {
        HStack {
            // 点位类型图标
            Image(systemName: point.pointType == .origin ? "mappin.circle.fill" : "mappin")
                .foregroundColor(point.pointType == .origin ? .red : .blue)

            VStack(alignment: .leading, spacing: 2) {
                Text(point.name)
                    .font(.subheadline)

                Text(String(format: "%.6f, %.6f", point.coordinate.latitude, point.coordinate.longitude))
                    .font(.caption)
                    .foregroundColor(.gray)
            }

            Spacer()

            // 编辑按钮
            Button(action: {
                showEditDialog = true
            }) {
                Image(systemName: "pencil.circle")
                    .foregroundColor(.blue)
            }
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive, action: onDelete) {
                Label("删除", systemImage: "trash")
            }
        }
    }
}

// MARK: - Create Case Dialog

/// 新建案例对话框
struct CreateCaseDialog: View {

    let onCreate: (String, String?) -> Void

    @State private var name: String = ""
    @State private var description: String = ""
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("案例名称", text: $name)
                }

                Section {
                    TextField("案例描述（可选）", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("新建案例")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("创建") {
                        onCreate(name, description.isEmpty ? nil : description)
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
}
