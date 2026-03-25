// LifeCircleOriginSelectorView.swift
// 生活圈多选原点选择器
// 见 PHASE_V4_SPEC.md 2.2节

import SwiftUI

/// 生活圈原点多选选择器
/// 从所有案例的原点中选择3个作为生活圈点位
struct LifeCircleOriginSelectorView: View {

    @ObservedObject var lifeCircleViewModel: LifeCircleViewModel
    @ObservedObject var mapViewModel: MapViewModel

    @Environment(\.dismiss) private var dismiss

    // MARK: - Body

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 提示说明
                selectionHintBanner

                // 原点列表（所有案例的原点）
                let allOrigins = getAllOrigins()

                if allOrigins.isEmpty {
                    emptyState
                } else {
                    originList(allOrigins)
                }

                Spacer(minLength: 0)

                // 底部确认按钮
                confirmButton
            }
            .navigationTitle("选择3个位置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
            }
            .alert("提示", isPresented: Binding(
                get: { lifeCircleViewModel.errorMessage != nil },
                set: { if !$0 { lifeCircleViewModel.errorMessage = nil } }
            )) {
                Button("好的") { lifeCircleViewModel.errorMessage = nil }
            } message: {
                Text(lifeCircleViewModel.errorMessage ?? "")
            }
        }
        .onAppear {
            lifeCircleViewModel.resetWizard()
        }
    }

    // MARK: - Subviews

    private var selectionHintBanner: some View {
        HStack(spacing: 8) {
            Image(systemName: "info.circle.fill")
                .foregroundColor(.blue)
            Text("请选择3个原点作为家、公司和日常场所")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
            // 选中计数器
            Text("\(lifeCircleViewModel.selectedOrigins.count)/3")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(lifeCircleViewModel.selectedOrigins.count == 3 ? .green : .orange)
        }
        .padding(12)
        .background(Color(.systemGray6))
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "mappin.slash")
                .font(.system(size: 48))
                .foregroundColor(.gray)
            Text("暂无原点")
                .font(.headline)
                .foregroundColor(.gray)
            Text("请先在堪舆管理中添加原点")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
        }
    }

    private func originList(_ origins: [GeoPoint]) -> some View {
        List {
            ForEach(origins) { origin in
                originRow(origin)
            }
        }
        .listStyle(.plain)
    }

    private func originRow(_ origin: GeoPoint) -> some View {
        let isSelected = lifeCircleViewModel.selectedOrigins.contains(where: { $0.id == origin.id })
        let selectionIndex = lifeCircleViewModel.selectedOrigins.firstIndex(where: { $0.id == origin.id })

        return Button(action: {
            lifeCircleViewModel.toggleOriginSelection(origin)
        }) {
            HStack(spacing: 12) {
                // 选择状态圆圈
                ZStack {
                    Circle()
                        .strokeBorder(isSelected ? Color.purple : Color.gray.opacity(0.4), lineWidth: 2)
                        .frame(width: 28, height: 28)

                    if isSelected, let index = selectionIndex {
                        Circle()
                            .fill(Color.purple)
                            .frame(width: 22, height: 22)
                        Text("\(index + 1)")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                    }
                }

                // 图标
                Image(systemName: origin.isGPSOrigin ? "location.fill" : "mappin.circle.fill")
                    .foregroundColor(isSelected ? .purple : .red)
                    .font(.system(size: 18))

                // 名称和坐标
                VStack(alignment: .leading, spacing: 3) {
                    Text(origin.name)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primary)

                    Text(String(format: "%.5f, %.5f",
                                origin.coordinate.latitude,
                                origin.coordinate.longitude))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                // 案例标识
                Text("案例 \(origin.caseId)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color(.systemGray5))
                    .cornerRadius(4)
            }
            .padding(.vertical, 4)
        }
        .listRowBackground(isSelected ? Color.purple.opacity(0.05) : Color.clear)
    }

    private var confirmButton: some View {
        Button(action: {
            if lifeCircleViewModel.confirmOriginSelection() {
                dismiss()
            }
        }) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                Text(lifeCircleViewModel.selectedOrigins.count == 3
                     ? "确认选择"
                     : "还需选择 \(3 - lifeCircleViewModel.selectedOrigins.count) 个")
            }
            .font(.system(size: 17, weight: .semibold))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(lifeCircleViewModel.selectedOrigins.count == 3
                        ? Color.purple
                        : Color.gray.opacity(0.4))
            .foregroundColor(.white)
            .cornerRadius(12)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .disabled(lifeCircleViewModel.selectedOrigins.count != 3)
    }

    // MARK: - Data

    /// 获取所有案例的原点列表
    private func getAllOrigins() -> [GeoPoint] {
        let cases = mapViewModel.getAllCases()
        var origins: [GeoPoint] = []
        for fengShuiCase in cases {
            let caseOrigins = (try? getAllOriginsForCase(fengShuiCase.id)) ?? []
            origins.append(contentsOf: caseOrigins)
        }
        return origins
    }

    private func getAllOriginsForCase(_ caseId: Int) throws -> [GeoPoint] {
        return mapViewModel.getOriginsForCase(caseId)
    }
}
