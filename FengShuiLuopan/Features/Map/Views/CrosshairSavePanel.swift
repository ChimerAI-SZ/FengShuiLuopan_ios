// CrosshairSavePanel.swift
// 十字准心保存面板
// 见 PHASE_V3_SPEC.md 2.2-2.3节

import SwiftUI

/// 十字准心保存面板
/// 十字准心模式时显示在地图底部
struct CrosshairSavePanel: View {

    @ObservedObject var mapViewModel: MapViewModel
    @State private var selectedCaseId: Int?
    @State private var selectedPointType: PointType = .destination
    @State private var pointName: String = ""

    let onSave: () -> Void
    let onCancel: () -> Void

    // MARK: - Body

    var body: some View {
        VStack(spacing: 16) {
            // 提示文字
            VStack(alignment: .leading, spacing: 8) {
                Text("调整位置")
                    .font(.headline)

                Text("拖拽地图微调十字准心位置，调整好后点击下面按钮保存")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Divider()

            // 案例选择
            VStack(alignment: .leading, spacing: 8) {
                Text("保存为：")
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Picker("案例", selection: $selectedCaseId) {
                    Text("请选择案例").tag(nil as Int?)
                    ForEach(mapViewModel.getAllCases(), id: \.id) { case_ in
                        Text(case_.name).tag(Optional(case_.id))
                    }
                }
                .pickerStyle(.menu)
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            // 点位类型选择
            VStack(alignment: .leading, spacing: 8) {
                Picker("点位类型", selection: $selectedPointType) {
                    Text("原点").tag(PointType.origin)
                    Text("终点").tag(PointType.destination)
                }
                .pickerStyle(.segmented)
            }

            // 名称输入
            VStack(alignment: .leading, spacing: 8) {
                Text("点位名称")
                    .font(.subheadline)
                    .fontWeight(.semibold)

                TextField("输入点位名称", text: $pointName)
                    .textFieldStyle(.roundedBorder)
            }

            // 按钮
            HStack(spacing: 12) {
                Button {
                    onCancel()
                } label: {
                    Text("取消")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color(.systemGray4))
                        .foregroundColor(.primary)
                        .cornerRadius(8)
                }

                Button {
                    guard let caseId = selectedCaseId, !pointName.isEmpty else { return }
                    mapViewModel.saveCrosshairPosition(
                        caseId: caseId,
                        pointType: selectedPointType,
                        name: pointName
                    )
                    onSave()
                } label: {
                    Text("保存")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(selectedCaseId != nil && !pointName.isEmpty ? Color.purple : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .disabled(selectedCaseId == nil || pointName.isEmpty)
            }
        }
        .padding(16)
        .background(.ultraThinMaterial)
        .cornerRadius(12, corners: [.topLeft, .topRight])
        .onAppear {
            // 初始化：使用当前案例或第一个案例
            if let currentCaseId = mapViewModel.currentCaseId {
                selectedCaseId = currentCaseId
            } else {
                selectedCaseId = mapViewModel.getAllCases().first?.id
            }

            // 初始化名称：使用POI名称（如果有的话）
            pointName = mapViewModel.crosshairPOIName
        }
    }
}

// MARK: - Corner Radius Extension

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}
