// OriginSelectorView.swift
// 原点选择器
// 见 PHASE_V2_SPEC.md

import SwiftUI

/// 原点选择器
struct OriginSelectorView: View {

    let origins: [GeoPoint]
    let onSelect: (GeoPoint) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            if origins.isEmpty {
                VStack {
                    Spacer()
                    Text("暂无原点，请在堪舆管理中添加")
                        .foregroundColor(.gray)
                    Spacer()
                }
            } else {
                List {
                    ForEach(origins) { origin in
                        Button(action: {
                            onSelect(origin)
                            dismiss()
                        }) {
                            HStack {
                                Image(systemName: origin.isGPSOrigin ? "location.fill" : "mappin.circle.fill")
                                    .foregroundColor(.red)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(origin.name)
                                        .font(.headline)
                                        .foregroundColor(.primary)

                                    Text(String(format: "%.6f, %.6f", origin.coordinate.latitude, origin.coordinate.longitude))
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("选择原点")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("取消") {
                    dismiss()
                }
            }
        }
    }
}
