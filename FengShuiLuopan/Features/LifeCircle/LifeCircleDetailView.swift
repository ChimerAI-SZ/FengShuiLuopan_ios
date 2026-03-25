// LifeCircleDetailView.swift
// 生活圈详情对话框
// 见 PHASE_V4_SPEC.md 5.2节

import SwiftUI

/// 生活圈详情对话框
/// 显示三点之间的详细连线信息
struct LifeCircleDetailView: View {

    let lifeCircle: LifeCircleData
    let connections: [LifeCircleConnection]

    @Environment(\.dismiss) private var dismiss

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // 三个点的基本信息
                    pointInfoSection

                    Divider()

                    // 三条连线信息
                    connectionsSection
                }
                .padding(16)
            }
            .navigationTitle("生活圈详情")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("关闭") {
                        dismiss()
                    }
                }
            }
        }
    }

    // MARK: - Subviews

    private var pointInfoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("三个位置")
                .font(.headline)

            ForEach([LifeCirclePointType.home, .work, .entertainment], id: \.self) { type in
                let point = lifeCircle.point(for: type)
                pointInfoRow(type: type, point: point)
            }
        }
    }

    private func pointInfoRow(type: LifeCirclePointType, point: GeoPoint) -> some View {
        HStack(spacing: 12) {
            // 角色图标
            ZStack {
                Circle()
                    .fill(colorForType(type))
                    .frame(width: 36, height: 36)
                Image(systemName: type.icon)
                    .foregroundColor(.white)
                    .font(.system(size: 16))
            }

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 4) {
                    Text(type.displayName)
                        .font(.caption)
                        .foregroundColor(colorForType(type))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(colorForType(type).opacity(0.1))
                        .cornerRadius(4)
                    Text(point.name)
                        .font(.system(size: 15, weight: .medium))
                }
                Text(String(format: "%.6f, %.6f",
                            point.coordinate.latitude,
                            point.coordinate.longitude))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(10)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }

    private var connectionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("三角连线")
                .font(.headline)

            // 家→公司
            connectionRow(
                from: lifeCircle.homePoint,
                to: lifeCircle.workPoint,
                label: "家 → 公司",
                color: Color(hex: "00C853")
            )

            // 公司→日常场所
            connectionRow(
                from: lifeCircle.workPoint,
                to: lifeCircle.entertainmentPoint,
                label: "公司 → 日常场所",
                color: Color(hex: "2196F3")
            )

            // 日常场所→家
            connectionRow(
                from: lifeCircle.entertainmentPoint,
                to: lifeCircle.homePoint,
                label: "日常场所 → 家",
                color: Color(hex: "FF9800")
            )
        }
    }

    private func connectionRow(
        from: GeoPoint,
        to: GeoPoint,
        label: String,
        color: Color
    ) -> some View {
        // 找到对应的连线数据
        let connection = connections.first {
            $0.from.id == from.id && $0.to.id == to.id
        }

        return VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(color)
                    .frame(width: 18, height: 4)
                Text(label)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(color)
            }

            if let conn = connection {
                HStack(spacing: 16) {
                    detailBadge(icon: "location.north.fill",
                                value: conn.formattedBearing)
                    detailBadge(icon: "arrow.triangle.2.circlepath",
                                value: conn.shanName)
                    detailBadge(icon: "ruler",
                                value: conn.formattedDistance)
                }
            }
        }
        .padding(10)
        .background(color.opacity(0.07))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(color.opacity(0.3), lineWidth: 1)
        )
    }

    private func detailBadge(icon: String, value: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
            Text(value)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.primary)
        }
    }

    // MARK: - Helpers

    private func colorForType(_ type: LifeCirclePointType) -> Color {
        switch type {
        case .home:          return Color(hex: "00C853")
        case .work:          return Color(hex: "2196F3")
        case .entertainment: return Color(hex: "FF9800")
        }
    }
}

// MARK: - Color Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
