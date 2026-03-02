// MultiConnectionInfoPanel.swift
// 多连线信息面板
// 见 PHASE_V2_SPEC.md

import SwiftUI

/// 多连线信息面板
struct MultiConnectionInfoPanel: View {

    let connections: [Connection]
    let onClose: () -> Void

    @State private var selectedIndex: Int = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 标题栏
            HStack {
                Text("连线信息")
                    .font(.headline)
                Spacer()
                Button(action: onClose) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }

            // 连线选择器（如果有多条连线）
            if connections.count > 1 {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(Array(connections.enumerated()), id: \.offset) { index, connection in
                            Button(action: {
                                selectedIndex = index
                            }) {
                                HStack {
                                    Circle()
                                        .fill(getColor(for: index))
                                        .frame(width: 12, height: 12)
                                    Text(connection.destination.name)
                                        .font(.caption)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(selectedIndex == index ? Color.blue.opacity(0.2) : Color.gray.opacity(0.1))
                                .cornerRadius(16)
                            }
                        }
                    }
                }
            }

            Divider()

            // 当前选中的连线信息
            if connections.indices.contains(selectedIndex) {
                let connection = connections[selectedIndex]

                // 原点信息
                Text("原点: \(connection.origin.name)")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                Text(connection.origin.coordinate.description)
                    .font(.caption)
                    .foregroundColor(.gray)

                Divider()

                // 终点信息
                HStack {
                    Circle()
                        .fill(getColor(for: selectedIndex))
                        .frame(width: 12, height: 12)
                    Text("终点: \(connection.destination.name)")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                Text(connection.destination.coordinate.description)
                    .font(.caption)
                    .foregroundColor(.gray)

                Divider()

                // 方位角
                InfoRow(label: "方位角", value: connection.formattedBearing)

                // 距离
                InfoRow(label: "距离", value: connection.formattedDistance)

                // 24山
                InfoRow(label: "24山", value: connection.mountain.name)

                // 八卦
                InfoRow(label: "八卦", value: connection.trigram.name)

                // 五行
                InfoRow(label: "五行", value: connection.wuxing.rawValue)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(radius: 8)
    }

    /// 获取连线颜色
    private func getColor(for index: Int) -> Color {
        let uiColor = ConnectionColorHelper.getColor(at: index)
        return Color(uiColor)
    }
}
