// AddPointDialog.swift
// 加点对话框
// 见 PHASE_V2_SPEC.md

import SwiftUI

/// 加点对话框
struct AddPointDialog: View {

    let coordinate: WGS84Coordinate
    let cases: [FengShuiCase]
    let onAdd: (String, Int, PointType) -> Void

    @State private var pointName: String = ""
    @State private var selectedCaseId: Int?
    @State private var selectedPointType: PointType = .destination
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                // 点位名称
                Section {
                    TextField("点位名称", text: $pointName)
                } header: {
                    Text("名称")
                }

                // 选择案例
                Section {
                    if cases.isEmpty {
                        Text("暂无案例，请先在堪舆管理中创建案例")
                            .foregroundColor(.gray)
                    } else {
                        Picker("选择案例", selection: $selectedCaseId) {
                            Text("请选择").tag(nil as Int?)
                            ForEach(cases) { fengShuiCase in
                                Text(fengShuiCase.name).tag(fengShuiCase.id as Int?)
                            }
                        }
                    }
                } header: {
                    Text("所属案例")
                }

                // 点位类型
                Section {
                    Picker("点位类型", selection: $selectedPointType) {
                        Text("原点").tag(PointType.origin)
                        Text("终点").tag(PointType.destination)
                    }
                    .pickerStyle(.segmented)
                } header: {
                    Text("类型")
                }

                // 坐标信息
                Section {
                    HStack {
                        Text("纬度")
                        Spacer()
                        Text(String(format: "%.6f", coordinate.latitude))
                            .foregroundColor(.gray)
                    }
                    HStack {
                        Text("经度")
                        Spacer()
                        Text(String(format: "%.6f", coordinate.longitude))
                            .foregroundColor(.gray)
                    }
                } header: {
                    Text("坐标")
                }
            }
            .navigationTitle("添加点位")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        if let caseId = selectedCaseId {
                            onAdd(pointName, caseId, selectedPointType)
                            dismiss()
                        }
                    }
                    .disabled(pointName.isEmpty || selectedCaseId == nil)
                }
            }
        }
    }
}
