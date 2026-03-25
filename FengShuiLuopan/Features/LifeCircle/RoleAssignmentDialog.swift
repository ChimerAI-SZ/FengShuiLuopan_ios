// RoleAssignmentDialog.swift
// 生活圈角色分配对话框
// 见 PHASE_V4_SPEC.md 3节

import SwiftUI

/// 生活圈角色分配对话框
/// 显示3个原点，让用户为每个分配角色（家/公司/日常场所）
struct RoleAssignmentDialog: View {

    @ObservedObject var lifeCircleViewModel: LifeCircleViewModel
    @ObservedObject var mapViewModel: MapViewModel

    @Environment(\.dismiss) private var dismiss

    // MARK: - Body

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 标题和说明
                VStack(alignment: .leading, spacing: 8) {
                    Text("生活圈角色分配")
                        .font(.headline)

                    HStack(spacing: 4) {
                        Image(systemName: "lightbulb.fill")
                            .foregroundColor(.orange)
                            .font(.system(size: 14))
                        Text("系统已根据名称智能推荐角色")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .background(Color(.systemGray6))

                Divider()

                // 角色分配列表
                ScrollView {
                    VStack(spacing: 16) {
                        ForEach(Array(lifeCircleViewModel.selectedOrigins.enumerated()), id: \.offset) { index, origin in
                            roleAssignmentRow(origin, index: index)
                        }
                    }
                    .padding(16)
                }

                Divider()

                // 底部按钮
                HStack(spacing: 12) {
                    Button(action: {
                        dismiss()
                    }) {
                        Text("取消")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color(.systemGray4))
                            .foregroundColor(.primary)
                            .cornerRadius(8)
                    }

                    Button(action: {
                        lifeCircleViewModel.confirmRoleAssignment(mapViewModel: mapViewModel)
                        dismiss()
                    }) {
                        Text("确定")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(lifeCircleViewModel.isRoleAssignmentValid
                                        ? Color.purple
                                        : Color.gray.opacity(0.4))
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                    .disabled(!lifeCircleViewModel.isRoleAssignmentValid)
                }
                .padding(16)
            }
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // MARK: - Subviews

    private func roleAssignmentRow(_ origin: GeoPoint, index: Int) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            // 位置标题
            HStack(spacing: 8) {
                Text("位置\(index + 1)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Text(origin.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)

                Spacer()

                // 推荐标签
                if lifeCircleViewModel.isSmartRecommended {
                    HStack(spacing: 2) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 12))
                        Text("推荐")
                            .font(.caption2)
                    }
                    .foregroundColor(.green)
                }
            }

            // 角色选择器
            Picker("角色", selection: Binding(
                get: { lifeCircleViewModel.role(for: origin) ?? .home },
                set: { lifeCircleViewModel.setRole($0, for: origin) }
            )) {
                ForEach(LifeCirclePointType.allCases, id: \.self) { role in
                    HStack(spacing: 6) {
                        Image(systemName: role.icon)
                        Text(role.displayName)
                    }
                    .tag(role)
                }
            }
            .pickerStyle(.segmented)
        }
        .padding(12)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

// MARK: - Preview

struct RoleAssignmentDialog_Previews: PreviewProvider {
    static var previews: some View {
        RoleAssignmentDialog(
            lifeCircleViewModel: LifeCircleViewModel(),
            mapViewModel: MapViewModel()
        )
    }
}
