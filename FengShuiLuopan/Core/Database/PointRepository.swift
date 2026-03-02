// PointRepository.swift
// 点位数据仓库
// 见 ARCHITECTURE.md 第6节, PHASE_V2_SPEC.md

import Foundation
#if canImport(SQLite)
import SQLite
#elseif canImport(SQLite3)
import SQLite3
#endif

/// 点位数据仓库
class PointRepository {

    // MARK: - Properties

    private let db: Connection

    // MARK: - Initialization

    init() throws {
        self.db = try DatabaseManager.shared.getConnection()
    }

    // MARK: - CRUD Operations

    /// 创建点位
    func createPoint(
        caseId: Int,
        name: String,
        coordinate: WGS84Coordinate,
        pointType: PointType,
        isGPSOrigin: Bool = false
    ) throws -> GeoPoint {
        let now = Date()

        let insert = DatabaseSchema.pointsTable.insert(
            DatabaseSchema.pointCaseId <- Int64(caseId),
            DatabaseSchema.pointName <- name,
            DatabaseSchema.pointLatitude <- coordinate.latitude,
            DatabaseSchema.pointLongitude <- coordinate.longitude,
            DatabaseSchema.pointType <- pointType.rawValue,
            DatabaseSchema.pointIsGPSOrigin <- isGPSOrigin,
            DatabaseSchema.pointCreatedAt <- now,
            DatabaseSchema.pointUpdatedAt <- now
        )

        do {
            let rowId = try db.run(insert)
            return GeoPoint(
                id: Int(rowId),
                caseId: caseId,
                name: name,
                coordinate: coordinate,
                pointType: pointType,
                isGPSOrigin: isGPSOrigin,
                createdAt: now,
                updatedAt: now
            )
        } catch {
            throw DatabaseError.insertFailed("创建点位失败: \(error)")
        }
    }

    /// 获取案例的所有点位
    func getPointsByCase(_ caseId: Int) throws -> [GeoPoint] {
        do {
            let query = DatabaseSchema.pointsTable
                .filter(DatabaseSchema.pointCaseId == Int64(caseId))
                .order(DatabaseSchema.pointCreatedAt.asc)

            var points: [GeoPoint] = []

            for row in try db.prepare(query) {
                let point = try parsePoint(from: row)
                points.append(point)
            }

            return points
        } catch {
            throw DatabaseError.queryFailed("查询点位失败: \(error)")
        }
    }

    /// 获取案例的所有原点（不含GPS原点）
    func getOriginsByCase(_ caseId: Int) throws -> [GeoPoint] {
        do {
            let query = DatabaseSchema.pointsTable
                .filter(DatabaseSchema.pointCaseId == Int64(caseId))
                .filter(DatabaseSchema.pointType == PointType.origin.rawValue)
                .filter(DatabaseSchema.pointIsGPSOrigin == false)
                .order(DatabaseSchema.pointCreatedAt.asc)

            var points: [GeoPoint] = []

            for row in try db.prepare(query) {
                let point = try parsePoint(from: row)
                points.append(point)
            }

            return points
        } catch {
            throw DatabaseError.queryFailed("查询原点失败: \(error)")
        }
    }

    /// 获取案例的所有终点
    func getDestinationsByCase(_ caseId: Int) throws -> [GeoPoint] {
        do {
            let query = DatabaseSchema.pointsTable
                .filter(DatabaseSchema.pointCaseId == Int64(caseId))
                .filter(DatabaseSchema.pointType == PointType.destination.rawValue)
                .order(DatabaseSchema.pointCreatedAt.asc)

            var points: [GeoPoint] = []

            for row in try db.prepare(query) {
                let point = try parsePoint(from: row)
                points.append(point)
            }

            return points
        } catch {
            throw DatabaseError.queryFailed("查询终点失败: \(error)")
        }
    }

    /// 根据ID获取点位
    func getPointById(_ id: Int) throws -> GeoPoint? {
        do {
            let query = DatabaseSchema.pointsTable.filter(DatabaseSchema.pointId == Int64(id))

            guard let row = try db.pluck(query) else {
                return nil
            }

            return try parsePoint(from: row)
        } catch {
            throw DatabaseError.queryFailed("查询点位失败: \(error)")
        }
    }

    /// 更新点位
    func updatePoint(_ point: GeoPoint) throws {
        let pointRow = DatabaseSchema.pointsTable.filter(DatabaseSchema.pointId == Int64(point.id))

        let update = pointRow.update(
            DatabaseSchema.pointName <- point.name,
            DatabaseSchema.pointLatitude <- point.coordinate.latitude,
            DatabaseSchema.pointLongitude <- point.coordinate.longitude,
            DatabaseSchema.pointUpdatedAt <- Date()
        )

        do {
            let updated = try db.run(update)
            if updated == 0 {
                throw DatabaseError.updateFailed("点位不存在")
            }
        } catch {
            throw DatabaseError.updateFailed("更新点位失败: \(error)")
        }
    }

    /// 删除点位
    func deletePoint(_ id: Int) throws {
        let pointRow = DatabaseSchema.pointsTable.filter(DatabaseSchema.pointId == Int64(id))

        do {
            let deleted = try db.run(pointRow.delete())
            if deleted == 0 {
                throw DatabaseError.deleteFailed("点位不存在")
            }
        } catch {
            throw DatabaseError.deleteFailed("删除点位失败: \(error)")
        }
    }

    /// 获取案例的原点数量（不含GPS原点）
    func getOriginCount(caseId: Int) throws -> Int {
        do {
            let query = DatabaseSchema.pointsTable
                .filter(DatabaseSchema.pointCaseId == Int64(caseId))
                .filter(DatabaseSchema.pointType == PointType.origin.rawValue)
                .filter(DatabaseSchema.pointIsGPSOrigin == false)

            return try db.scalar(query.count)
        } catch {
            throw DatabaseError.queryFailed("查询原点数量失败: \(error)")
        }
    }

    /// 获取案例的终点数量
    func getDestinationCount(caseId: Int) throws -> Int {
        do {
            let query = DatabaseSchema.pointsTable
                .filter(DatabaseSchema.pointCaseId == Int64(caseId))
                .filter(DatabaseSchema.pointType == PointType.destination.rawValue)

            return try db.scalar(query.count)
        } catch {
            throw DatabaseError.queryFailed("查询终点数量失败: \(error)")
        }
    }

    // MARK: - Private Helpers

    /// 从数据库行解析点位
    private func parsePoint(from row: Row) throws -> GeoPoint {
        guard let pointType = PointType(rawValue: row[DatabaseSchema.pointType]) else {
            throw DatabaseError.queryFailed("无效的点位类型")
        }

        return GeoPoint(
            id: Int(row[DatabaseSchema.pointId]),
            caseId: Int(row[DatabaseSchema.pointCaseId]),
            name: row[DatabaseSchema.pointName],
            coordinate: WGS84Coordinate(
                latitude: row[DatabaseSchema.pointLatitude],
                longitude: row[DatabaseSchema.pointLongitude]
            ),
            pointType: pointType,
            isGPSOrigin: row[DatabaseSchema.pointIsGPSOrigin],
            createdAt: row[DatabaseSchema.pointCreatedAt],
            updatedAt: row[DatabaseSchema.pointUpdatedAt]
        )
    }
}
