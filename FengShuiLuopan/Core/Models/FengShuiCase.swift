// FengShuiCase.swift
// 堪舆案例数据模型
// 见 PHASE_V2_SPEC.md

import Foundation

/// 堪舆案例
struct FengShuiCase: Identifiable, Codable {
    let id: Int
    var name: String
    var description: String?
    let createdAt: Date
    var updatedAt: Date

    init(id: Int, name: String, description: String? = nil, createdAt: Date = Date(), updatedAt: Date = Date()) {
        self.id = id
        self.name = name
        self.description = description
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

/// 案例限制常量
enum CaseConstants {
    /// 每案例最多原点数（不含GPS原点）
    static let MAX_ORIGINS_PER_CASE = 2

    /// 每案例最多终点数
    static let MAX_DESTINATIONS_PER_CASE = 5

    /// 试用版最多案例数
    static let MAX_CASES_TRIAL = 2

    /// 重复终点检测阈值（米）
    static let DUPLICATE_POINT_THRESHOLD = 300.0
}
