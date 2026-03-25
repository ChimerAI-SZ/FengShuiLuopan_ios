// LifeCircleViewModel.swift
// 生活圈视图模型
// 见 PHASE_V4_SPEC.md, ARCHITECTURE.md 10节

import Foundation
import Combine

/// 生活圈视图模型
/// 管理生活圈激活流程、角色推荐、连线计算
class LifeCircleViewModel: ObservableObject {

    // MARK: - Published Properties

    /// 向导步骤
    @Published var wizardStep: LifeCircleWizardStep = .selectingOrigins

    /// 当前向导中选中的原点（多选，按顺序）
    @Published var selectedOrigins: [GeoPoint] = []

    /// 角色分配（originId → LifeCirclePointType）
    @Published var roleAssignments: [Int: LifeCirclePointType] = [:]

    /// 已激活的生活圈数据
    @Published var activeLifeCircle: LifeCircleData?

    /// 已计算的生活圈连线
    @Published var lifeCircleConnections: [LifeCircleConnection] = []

    /// 每个点的"指入"连线
    @Published var incomingConnections: [Int: [LifeCircleConnection]] = [:]

    /// 是否正在显示角色分配对话框
    @Published var showRoleAssignment: Bool = false

    /// 是否正在显示生活圈详情
    @Published var showLifeCircleDetail: Bool = false

    /// 错误消息
    @Published var errorMessage: String?

    // MARK: - Private Properties

    /// 角色分配缓存（会话级别，Key: 原点ID集合）
    /// 见 ARCHITECTURE.md 10.6节
    private var roleAssignmentCache: [Set<Int>: [Int: LifeCirclePointType]] = [:]

    /// 智能推荐关键词（见 PHASE_V4_SPEC.md 3.2节）
    private let homeKeywords = Set(["家", "住宅", "小区", "公寓", "楼盘", "房", "宅", "居"])
    private let workKeywords = Set(["公司", "办公", "工作", "单位", "企业", "写字楼", "厂", "店"])
    private let entertainmentKeywords = Set(["餐厅", "商场", "健身", "娱乐", "咖啡", "超市", "饭店"])

    // MARK: - Initialization

    init() {}

    // MARK: - 向导流程

    /// 重置向导状态（开始新的生活圈激活流程）
    func resetWizard() {
        selectedOrigins = []
        roleAssignments = [:]
        wizardStep = .selectingOrigins
        showRoleAssignment = false
    }

    /// 切换原点选择（多选模式，最多3个）
    func toggleOriginSelection(_ origin: GeoPoint) {
        if let index = selectedOrigins.firstIndex(where: { $0.id == origin.id }) {
            selectedOrigins.remove(at: index)
        } else if selectedOrigins.count < 3 {
            selectedOrigins.append(origin)
        }
    }

    /// 确认原点选择，进入角色分配步骤
    /// - Returns: 是否成功（需要恰好3个原点）
    func confirmOriginSelection() -> Bool {
        guard selectedOrigins.count == 3 else {
            errorMessage = "请选择3个原点"
            return false
        }

        // 检查缓存
        let originIdSet = Set(selectedOrigins.map { $0.id })
        if let cached = roleAssignmentCache[originIdSet] {
            roleAssignments = cached
        } else {
            // 智能推荐
            roleAssignments = recommendRoles(for: selectedOrigins)
        }

        wizardStep = .assigningRoles
        showRoleAssignment = true
        return true
    }

    /// 确认角色分配，激活生活圈
    /// - Parameter mapViewModel: 地图视图模型（用于渲染）
    func confirmRoleAssignment(mapViewModel: MapViewModel) {
        guard selectedOrigins.count == 3 else { return }

        // 验证所有原点都有角色
        let allRolesAssigned = [LifeCirclePointType.home, .work, .entertainment].allSatisfy { role in
            roleAssignments.values.contains(role)
        }
        guard allRolesAssigned else {
            errorMessage = "请为每个位置分配不同的角色"
            return
        }

        // 保存到缓存（会话级别）
        let originIdSet = Set(selectedOrigins.map { $0.id })
        roleAssignmentCache[originIdSet] = roleAssignments

        // 构建 LifeCircleData
        guard
            let homeOriginId = roleAssignments.first(where: { $0.value == .home })?.key,
            let workOriginId = roleAssignments.first(where: { $0.value == .work })?.key,
            let entertainOriginId = roleAssignments.first(where: { $0.value == .entertainment })?.key,
            let homePoint = selectedOrigins.first(where: { $0.id == homeOriginId }),
            let workPoint = selectedOrigins.first(where: { $0.id == workOriginId }),
            let entertainPoint = selectedOrigins.first(where: { $0.id == entertainOriginId })
        else {
            errorMessage = "角色分配数据错误"
            return
        }

        let lifeCircle = LifeCircleData(
            homePoint: homePoint,
            workPoint: workPoint,
            entertainmentPoint: entertainPoint
        )

        // 计算连线
        let connections = calculateTriangleConnections(lifeCircle)
        let incoming = calculateAllIncomingConnections(lifeCircle)

        // 激活
        activeLifeCircle = lifeCircle
        lifeCircleConnections = connections
        incomingConnections = incoming
        wizardStep = .active
        showRoleAssignment = false

        // 通知 MapViewModel 渲染
        mapViewModel.activateLifeCircle(lifeCircle)
    }

    /// 退出生活圈模式
    /// - Parameter mapViewModel: 地图视图模型（用于恢复普通模式）
    func exitLifeCircle(mapViewModel: MapViewModel) {
        activeLifeCircle = nil
        lifeCircleConnections = []
        incomingConnections = [:]
        wizardStep = .selectingOrigins
        showRoleAssignment = false
        showLifeCircleDetail = false

        // 通知 MapViewModel 恢复普通模式
        mapViewModel.deactivateLifeCircle()
    }

    // MARK: - 智能角色推荐
    // 见 ARCHITECTURE.md 10.5节，PHASE_V4_SPEC.md 3.2节

    func recommendRoles(for origins: [GeoPoint]) -> [Int: LifeCirclePointType] {
        var scores: [Int: [LifeCirclePointType: Int]] = [:]

        // 计算每个原点对每个角色的匹配分数
        for origin in origins {
            let name = origin.name
            var roleScores: [LifeCirclePointType: Int] = [:]

            roleScores[.home]          = homeKeywords.filter { name.contains($0) }.count
            roleScores[.work]          = workKeywords.filter { name.contains($0) }.count
            roleScores[.entertainment] = entertainmentKeywords.filter { name.contains($0) }.count

            scores[origin.id] = roleScores
        }

        // 第一轮：明确匹配
        var assignments: [Int: LifeCirclePointType] = [:]
        var usedRoles: Set<LifeCirclePointType> = []

        for origin in origins {
            guard let roleScores = scores[origin.id] else { continue }
            let maxScore = roleScores.values.max() ?? 0
            if maxScore > 0 {
                let topRoles = roleScores.filter { $0.value == maxScore }
                if topRoles.count == 1,
                   let role = topRoles.first?.key,
                   !usedRoles.contains(role) {
                    assignments[origin.id] = role
                    usedRoles.insert(role)
                }
            }
        }

        // 第二轮：为剩余原点分配剩余角色（按列表顺序）
        let remainingOrigins = origins.filter { assignments[$0.id] == nil }
        let remainingRoles = [LifeCirclePointType.home, .work, .entertainment]
            .filter { !usedRoles.contains($0) }

        for (index, origin) in remainingOrigins.enumerated() {
            if index < remainingRoles.count {
                assignments[origin.id] = remainingRoles[index]
            }
        }

        return assignments
    }

    // MARK: - 连线计算

    /// 计算三角连线（家→公司→餐厅→家）
    private func calculateTriangleConnections(_ lifeCircle: LifeCircleData) -> [LifeCircleConnection] {
        return [
            buildConnection(from: lifeCircle.homePoint, to: lifeCircle.workPoint),
            buildConnection(from: lifeCircle.workPoint, to: lifeCircle.entertainmentPoint),
            buildConnection(from: lifeCircle.entertainmentPoint, to: lifeCircle.homePoint)
        ]
    }

    /// 计算所有点的"指入"连线
    /// 见 ARCHITECTURE.md 10.3节
    private func calculateAllIncomingConnections(
        _ lifeCircle: LifeCircleData
    ) -> [Int: [LifeCircleConnection]] {
        var result: [Int: [LifeCircleConnection]] = [:]
        for point in lifeCircle.allPoints {
            result[point.id] = calculateIncomingConnections(for: point, in: lifeCircle)
        }
        return result
    }

    /// 计算某点的"指入"连线（其他两点指向它的连线）
    /// 见 ARCHITECTURE.md 10.3节
    func calculateIncomingConnections(
        for point: GeoPoint,
        in lifeCircle: LifeCircleData
    ) -> [LifeCircleConnection] {
        return lifeCircle.allPoints
            .filter { $0.id != point.id }
            .map { fromPoint in buildConnection(from: fromPoint, to: point) }
    }

    /// 构建连线信息
    private func buildConnection(from: GeoPoint, to: GeoPoint) -> LifeCircleConnection {
        let distance = FengShuiEngine.calculateVincentyDistance(
            from: from.coordinate,
            to: to.coordinate
        )
        let bearing = FengShuiEngine.calculateRhumbBearing(
            from: from.coordinate,
            to: to.coordinate
        )
        let mountain = FengShuiEngine.bearingToMountain(bearing)
        return LifeCircleConnection(
            from: from,
            to: to,
            distance: distance,
            bearing: bearing,
            shanName: mountain.name
        )
    }

    // MARK: - 角色分配便利方法

    /// 获取某原点当前分配的角色
    func role(for origin: GeoPoint) -> LifeCirclePointType? {
        return roleAssignments[origin.id]
    }

    /// 设置某原点的角色（确保同一角色不重复分配）
    func setRole(_ role: LifeCirclePointType, for origin: GeoPoint) {
        // 移除其他原点的相同角色
        for (key, value) in roleAssignments where value == role && key != origin.id {
            roleAssignments.removeValue(forKey: key)
        }
        roleAssignments[origin.id] = role
    }

    /// 当前角色分配是否有效（3个不同角色，各不相同）
    var isRoleAssignmentValid: Bool {
        guard roleAssignments.count == 3 else { return false }
        let assignedRoles = Set(roleAssignments.values)
        return assignedRoles.count == 3
    }

    /// 是否在推荐模式（未经缓存）
    var isSmartRecommended: Bool {
        let originIdSet = Set(selectedOrigins.map { $0.id })
        return roleAssignmentCache[originIdSet] == nil
    }
}
