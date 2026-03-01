// DestinationSelectorView.swift
// 终点选择器（多选）
// 见 PHASE_V2_SPEC.md

import SwiftUI

/// 终点选择器
struct DestinationSelectorView: View {

    let destinations: [GeoPoint]
    let onConfirm: ([GeoPoint], GeoPoint) -> Void
    let origins: [GeoPoint]

    @State private var selectedDestinations: Set<Int> = []
    @State private var showOriginSelector: Bool = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if destinations.isEmpty {
                    Spacer()
                    Text("暂无终点，请在堪舆管理中添加")
                        .foregroundColor(.gray)
                    Spacer()
                } else {
                    // 全选/清空按钮
                    HStack {
                        Button("全选") {
                            selectedDestinations = Set(destinations.map { $0.id })
                        }
                        .disabled(destinations.isEmpty)

                        Spacer()

                        Button("清空") {
                            selectedDestinations.removeAll()
                        }
                        .disabled(selectedDestinations.isEmpty)
                    }
                    .padding()

                    // 终点列表
                    List {
                        ForEach(destinations) { destination in
                            Button(action: {
                                if selectedDestinations.contains(destination.id) {
                                    selectedDestinations.remove(destination.id)
                                } else {
                                    selectedDestinations.insert(destination.id)
                                }
                            }) {
                                HStack {
                                    Image(systemName: selectedDestinations.contains(destination.id) ? "checkmark.circle.fill" : "circle")
                                        .foregroundColor(selectedDestinations.contains(destination.id) ? .blue : .gray)

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(destination.name)
                                            .font(.headline)
                                            .foregroundColor(.primary)

                                        Text(String(format: "%.6f, %.6f", destination.coordinate.latitude, destination.coordinate.longitude))
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }

                                    Spacer()
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("选择终点")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("确定") {
                        showOriginSelector = true
                    }
                    .disabled(selectedDestinations.isEmpty)
                }
            }
            .sheet(isPresented: $showOriginSelector) {
                OriginSelectorView(origins: origins) { selectedOrigin in
                    let selected = destinations.filter { selectedDestinations.contains($0.id) }
                    onConfirm(selected, selectedOrigin)
                    dismiss()
                }
            }
        }
    }
}
