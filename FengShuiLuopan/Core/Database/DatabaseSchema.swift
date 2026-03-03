// DatabaseSchema.swift
// 数据库架构定义
// 见 ARCHITECTURE.md 第6节, PHASE_V2_SPEC.md

import Foundation
import SQLite

/// 数据库架构管理
class DatabaseSchema {

    // MARK: - Table Definitions

    /// 案例表
    static let casesTable = Table("cases")
    static let caseId = Expression<Int64>("id")
    static let caseName = Expression<String>("name")
    static let caseDescription = Expression<String?>("description")
    static let caseCreatedAt = Expression<Date>("created_at")
    static let caseUpdatedAt = Expression<Date>("updated_at")

    /// 点位表
    static let pointsTable = Table("points")
    static let pointId = Expression<Int64>("id")
    static let pointCaseId = Expression<Int64>("case_id")
    static let pointName = Expression<String>("name")
    static let pointLatitude = Expression<Double>("latitude")
    static let pointLongitude = Expression<Double>("longitude")
    static let pointType = Expression<String>("point_type")  // "origin" or "destination"
    static let pointIsGPSOrigin = Expression<Bool>("is_gps_origin")
    static let pointCreatedAt = Expression<Date>("created_at")
    static let pointUpdatedAt = Expression<Date>("updated_at")

    // MARK: - Schema Creation

    /// 创建所有表
    static func createTables(in db: SQLite.Connection) throws {
        // 创建案例表
        try db.run(casesTable.create(ifNotExists: true) { t in
            t.column(caseId, primaryKey: .autoincrement)
            t.column(caseName)
            t.column(caseDescription)
            t.column(caseCreatedAt)
            t.column(caseUpdatedAt)
        })

        // 创建点位表
        try db.run(pointsTable.create(ifNotExists: true) { t in
            t.column(pointId, primaryKey: .autoincrement)
            t.column(pointCaseId)
            t.column(pointName)
            t.column(pointLatitude)
            t.column(pointLongitude)
            t.column(pointType)
            t.column(pointIsGPSOrigin, defaultValue: false)
            t.column(pointCreatedAt)
            t.column(pointUpdatedAt)

            // 外键约束
            t.foreignKey(pointCaseId, references: casesTable, caseId, delete: .cascade)
        })

        // 创建索引
        try createIndexes(in: db)
    }

    /// 创建索引
    private static func createIndexes(in db: SQLite.Connection) throws {
        // 案例名称索引（用于搜索）
        try db.execute("CREATE INDEX IF NOT EXISTS idx_cases_name ON cases(name)")

        // 点位案例ID索引（用于查询案例的所有点位）
        try db.execute("CREATE INDEX IF NOT EXISTS idx_points_case_id ON points(case_id)")

        // 点位类型索引（用于过滤原点/终点）
        try db.execute("CREATE INDEX IF NOT EXISTS idx_points_type ON points(point_type)")

        // GPS原点索引（用于快速查找GPS原点）
        try db.execute("CREATE INDEX IF NOT EXISTS idx_points_gps_origin ON points(is_gps_origin)")
    }
}
