// CaseRepository.swift
// 案例数据仓库
// 见 ARCHITECTURE.md 第6节, PHASE_V2_SPEC.md

import Foundation
import SQLite

/// 案例数据仓库
class CaseRepository {

    // MARK: - Properties

    private let db: Connection

    // MARK: - Initialization

    init() throws {
        self.db = try DatabaseManager.shared.getConnection()
    }

    // MARK: - CRUD Operations

    /// 创建案例
    func createCase(name: String, description: String? = nil) throws -> FengShuiCase {
        let now = Date()

        let insert = DatabaseSchema.casesTable.insert(
            DatabaseSchema.caseName <- name,
            DatabaseSchema.caseDescription <- description,
            DatabaseSchema.caseCreatedAt <- now,
            DatabaseSchema.caseUpdatedAt <- now
        )

        do {
            let rowId = try db.run(insert)
            return FengShuiCase(
                id: Int(rowId),
                name: name,
                description: description,
                createdAt: now,
                updatedAt: now
            )
        } catch {
            throw DatabaseError.insertFailed("创建案例失败: \(error)")
        }
    }

    /// 获取所有案例
    func getAllCases() throws -> [FengShuiCase] {
        do {
            let query = DatabaseSchema.casesTable.order(DatabaseSchema.caseCreatedAt.desc)
            var cases: [FengShuiCase] = []

            for row in try db.prepare(query) {
                let fengShuiCase = FengShuiCase(
                    id: Int(row[DatabaseSchema.caseId]),
                    name: row[DatabaseSchema.caseName],
                    description: row[DatabaseSchema.caseDescription],
                    createdAt: row[DatabaseSchema.caseCreatedAt],
                    updatedAt: row[DatabaseSchema.caseUpdatedAt]
                )
                cases.append(fengShuiCase)
            }

            return cases
        } catch {
            throw DatabaseError.queryFailed("查询案例失败: \(error)")
        }
    }

    /// 根据ID获取案例
    func getCaseById(_ id: Int) throws -> FengShuiCase? {
        do {
            let query = DatabaseSchema.casesTable.filter(DatabaseSchema.caseId == Int64(id))

            guard let row = try db.pluck(query) else {
                return nil
            }

            return FengShuiCase(
                id: Int(row[DatabaseSchema.caseId]),
                name: row[DatabaseSchema.caseName],
                description: row[DatabaseSchema.caseDescription],
                createdAt: row[DatabaseSchema.caseCreatedAt],
                updatedAt: row[DatabaseSchema.caseUpdatedAt]
            )
        } catch {
            throw DatabaseError.queryFailed("查询案例失败: \(error)")
        }
    }

    /// 搜索案例（按名称）
    func searchCases(keyword: String) throws -> [FengShuiCase] {
        do {
            let query = DatabaseSchema.casesTable
                .filter(DatabaseSchema.caseName.like("%\(keyword)%"))
                .order(DatabaseSchema.caseCreatedAt.desc)

            var cases: [FengShuiCase] = []

            for row in try db.prepare(query) {
                let fengShuiCase = FengShuiCase(
                    id: Int(row[DatabaseSchema.caseId]),
                    name: row[DatabaseSchema.caseName],
                    description: row[DatabaseSchema.caseDescription],
                    createdAt: row[DatabaseSchema.caseCreatedAt],
                    updatedAt: row[DatabaseSchema.caseUpdatedAt]
                )
                cases.append(fengShuiCase)
            }

            return cases
        } catch {
            throw DatabaseError.queryFailed("搜索案例失败: \(error)")
        }
    }

    /// 更新案例
    func updateCase(_ fengShuiCase: FengShuiCase) throws {
        let caseRow = DatabaseSchema.casesTable.filter(DatabaseSchema.caseId == Int64(fengShuiCase.id))

        let update = caseRow.update(
            DatabaseSchema.caseName <- fengShuiCase.name,
            DatabaseSchema.caseDescription <- fengShuiCase.description,
            DatabaseSchema.caseUpdatedAt <- Date()
        )

        do {
            let updated = try db.run(update)
            if updated == 0 {
                throw DatabaseError.updateFailed("案例不存在")
            }
        } catch {
            throw DatabaseError.updateFailed("更新案例失败: \(error)")
        }
    }

    /// 删除案例
    func deleteCase(_ id: Int) throws {
        let caseRow = DatabaseSchema.casesTable.filter(DatabaseSchema.caseId == Int64(id))

        do {
            let deleted = try db.run(caseRow.delete())
            if deleted == 0 {
                throw DatabaseError.deleteFailed("案例不存在")
            }
        } catch {
            throw DatabaseError.deleteFailed("删除案例失败: \(error)")
        }
    }

    /// 获取案例数量
    func getCaseCount() throws -> Int {
        do {
            return try db.scalar(DatabaseSchema.casesTable.count)
        } catch {
            throw DatabaseError.queryFailed("查询案例数量失败: \(error)")
        }
    }
}
