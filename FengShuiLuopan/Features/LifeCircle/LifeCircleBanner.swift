// LifeCircleBanner.swift
// 生活圈顶部横幅
// 见 PHASE_V4_SPEC.md 5节

import SwiftUI

/// 生活圈模式顶部横幅
/// 显示在地图顶部，包含模式标题、详情按钮、退出按钮
struct LifeCircleBanner: View {

    @ObservedObject var lifeCircleViewModel: LifeCircleViewModel
    @ObservedObject var mapViewModel: MapViewModel

    var body: some View {
        HStack(spacing: 12) {
            // 生活圈图标和标题
            HStack(spacing: 6) {
                Image(systemName: "house.circle.fill")
                    .font(.system(size: 18))
                    .foregroundColor(.white)
                Text("生活圈模式")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
            }

            Spacer()

            // 详情按钮
            Button(action: {
                lifeCircleViewModel.showLifeCircleDetail = true
            }) {
                Text("详情")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.white.opacity(0.2))
                    .cornerRadius(6)
            }

            // 退出按钮
            Button(action: {
                lifeCircleViewModel.exitLifeCircle(mapViewModel: mapViewModel)
            }) {
                Text("退出")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.red.opacity(0.7))
                    .cornerRadius(6)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color.purple.opacity(0.85))
        .sheet(isPresented: $lifeCircleViewModel.showLifeCircleDetail) {
            if let lifeCircle = lifeCircleViewModel.activeLifeCircle {
                LifeCircleDetailView(
                    lifeCircle: lifeCircle,
                    connections: lifeCircleViewModel.lifeCircleConnections
                )
            }
        }
    }
}
