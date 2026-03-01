// FengShuiService.swift
// 风水业务逻辑服务
// 见 ARCHITECTURE.md, PHASE_V2_SPEC.md

import Foundation

/// 风水业务逻辑服务
class FengShuiService {

    // MARK: - Properties

    private let caseRepository: CaseRepository
    private let pointRepository: PointRepository
    private let engine: FengShuiEngine

    /// 是否已注册（试用版为false）
    var isRegistered: Bool = false

    // MARK: - Initialization

    init() throws {
        self.caseRepository = try CaseRepository()
        self.pointRepository = try PointRepository()
        self.engine = FengShuiEngine()
    }

    // MARK: - Case Management

    /// 创建案例
    func createCase(name: String, description: String? = nil) throws -> FengShuiCase {
        // 检查试用限制
        if !isRegistered {
            let existingCount = try caseRepository.getCaseCount()
            if existingCount >= CaseConstants.MAX_CASES_TRIAL {
                throw TrialLimitError(
                    limitType: .caseCount,
                    message: "试用版最多创建\(CaseConstants.MAX_CASES_TRIAL)个案例"
                )
            }
        }

        return try caseRepository.createCase(name: name, description: description)
    }

    /// 获取所有案例
    func getAllCases() throws -> [FengShuiCase] {
        return try caseRepository.getAllCases()
    }

    /// 搜索案例
    func searchCases(keyword: String) throws -> [FengShuiCase] {
        return try caseRepository.searchCases(keyword: keyword)
    }

    /// 更新案例
    func updateCase(_ fengShuiCase: FengShuiCase) throws {
        try caseRepository.updateCase(fengShuiCase)
    }

    /// 删除案例
    func deleteCase(_ id: Int) throws {
        try caseRepository.deleteCase(id)
    }

    // MARK: - Point Management

    /// 创建点位
    func createPoint(
        caseId: Int,
        name: String,
        coordinate: WGS84Coordinate,
        pointType: PointType
    ) throws -> GeoPoint {
        // 检查原点数量限制
        if pointType == .origin {
            let originCount = try pointRepository.getOriginCount(caseId: caseId)
            if originCount >= CaseConstants.MAX_ORIGINS_PER_CASE {
                throw TrialLimitError(
                    limitType: .originCount,
                    message: "每案例最多\(CaseConstants.MAX_ORIGINS_PER_CASE)个原点"
                )
            }
        }

        // 检查终点数量限制
        if pointType == .destination {
            let destCount = try pointRepository.getDestinationCount(caseId: caseId)
            if destCount >= CaseConstants.MAX_DESTINATIONS_PER_CASE {
                throw TrialLimitError(
                    limitType: .destinationCount,
                    message: "每案例最多\(CaseConstants.MAX_DESTINATIONS_PER_CASE)个终点"
                )
            }
        }

        // 重复终点检测（仅终点）
        if pointType == .destination {
            let existingPoints = try pointRepository.getPointsByCase(caseId)
            if isDuplicateDestination(coordinate, in: existingPoints) {
                throw DuplicatePointError(
                    message: "检测到\(Int(CaseConstants.DUPLICATE_POINT_THRESHOLD))米内已有终点"
                )
            }
        }

        return try pointRepository.createPoint(
            caseId: caseId,
            name: name,
            coordinate: coordinate,
            pointType: pointType
        )
    }

    /// 获取案例的所有点位
    func getPointsByCase(_ caseId: Int) throws -> [GeoPoint] {
        return try pointRepository.getPointsByCase(caseId)
    }

    /// 获取案例的所有原点
    func getOriginsByCase(_ caseId: Int) throws -> [GeoPoint] {
        return try pointRepository.getOriginsByCase(caseId)
    }

    /// 获取案例的所有终点
    func getDestinationsByCase(_ caseId: Int) throws -> [GeoPoint] {
        return try pointRepository.getDestinationsByCase(caseId)
    }

    /// 更新点位
    func updatePoint(_ point: GeoPoint) throws {
        try pointRepository.updatePoint(point)
    }

    /// 删除点位
    func deletePoint(_ id: Int) throws {
        try pointRepository.deletePoint(id)
    }

    // MARK: - Connection Calculation

    /// 计算连线信息
    func calculateConnection(from origin: GeoPoint, to destination: GeoPoint) -> Connection {
        let distance = engine.calculateDistance(from: origin.coordinate, to: destination.coordinate)
        let bearing = engine.calculateBearing(from: origin.coordinate, to: destination.coordinate)
        let mountain = engine.getMountain(bearing: bearing)
        let trigram = engine.getTrigram(mountain: mountain)
        let wuxing = engine.getWuXing(mountain: mountain)

        return Connection(
            origin: origin,
            destination: destination,
            distance: distance,
            bearing: bearing,
            mountain: mountain,
            trigram: trigram,
            wuxing: wuxing
        )
    }

    // MARK: - Duplicate Detection

    /// 检测重复终点（见ARCHITECTURE.md 4.7节）
    private func isDuplicateDestination(_ coordinate: WGS84Coordinate, in points: [GeoPoint]) -> Bool {
        for point in points where point.pointType == .destination {
            let distance = engine.calculateDistance(from: coordinate, to: point.coordinate)
            if distance <= CaseConstants.DUPLICATE_POINT_THRESHOLD {
                return true
            }
        }
        return false
    }
}

// MARK: - Custom Errors

/// 试用限制错误
struct TrialLimitError: Error {
    enum LimitType {
        case caseCount
        case originCount
        case destinationCount
    }

    let limitType: LimitType
    let message: String
}

/// 重复点位错误
struct DuplicatePointError: Error {
    let message: String
}
