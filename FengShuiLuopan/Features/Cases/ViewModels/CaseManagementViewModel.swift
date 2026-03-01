// CaseManagementViewModel.swift
// 案例管理视图模型
// 见 PHASE_V2_SPEC.md

import Foundation
import Combine

/// 案例管理视图模型
class CaseManagementViewModel: ObservableObject {

    // MARK: - Published Properties

    /// 所有案例
    @Published var cases: [FengShuiCase] = []

    /// 搜索关键词
    @Published var searchKeyword: String = ""

    /// 展开的案例ID集合
    @Published var expandedCaseIds: Set<Int> = []

    /// 案例对应的点位字典
    @Published var casePoints: [Int: [GeoPoint]] = [:]

    /// 错误消息
    @Published var errorMessage: String?

    /// 显示新建案例对话框
    @Published var showCreateCaseDialog: Bool = false

    // MARK: - Private Properties

    private let service: FengShuiService
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    init() {
        do {
            self.service = try FengShuiService()
            setupSearchObserver()
            loadCases()
        } catch {
            self.service = try! FengShuiService()
            self.errorMessage = "初始化失败: \(error.localizedDescription)"
        }
    }

    // MARK: - Setup

    /// 设置搜索观察者
    private func setupSearchObserver() {
        $searchKeyword
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .sink { [weak self] keyword in
                self?.performSearch(keyword: keyword)
            }
            .store(in: &cancellables)
    }

    // MARK: - Case Management

    /// 加载所有案例
    func loadCases() {
        do {
            cases = try service.getAllCases()
        } catch {
            errorMessage = "加载案例失败: \(error.localizedDescription)"
        }
    }

    /// 搜索案例
    private func performSearch(keyword: String) {
        do {
            if keyword.isEmpty {
                cases = try service.getAllCases()
            } else {
                cases = try service.searchCases(keyword: keyword)
            }
        } catch {
            errorMessage = "搜索失败: \(error.localizedDescription)"
        }
    }

    /// 创建案例
    func createCase(name: String, description: String?) {
        do {
            let newCase = try service.createCase(name: name, description: description)
            cases.insert(newCase, at: 0)
            showCreateCaseDialog = false
        } catch let error as TrialLimitError {
            errorMessage = error.message
        } catch {
            errorMessage = "创建案例失败: \(error.localizedDescription)"
        }
    }

    /// 更新案例
    func updateCase(_ fengShuiCase: FengShuiCase) {
        do {
            try service.updateCase(fengShuiCase)
            loadCases()
        } catch {
            errorMessage = "更新案例失败: \(error.localizedDescription)"
        }
    }

    /// 删除案例
    func deleteCase(_ id: Int) {
        do {
            try service.deleteCase(id)
            cases.removeAll { $0.id == id }
            casePoints.removeValue(forKey: id)
            expandedCaseIds.remove(id)
        } catch {
            errorMessage = "删除案例失败: \(error.localizedDescription)"
        }
    }

    // MARK: - Point Management

    /// 加载案例的点位
    func loadPoints(for caseId: Int) {
        do {
            let points = try service.getPointsByCase(caseId)
            casePoints[caseId] = points
        } catch {
            errorMessage = "加载点位失败: \(error.localizedDescription)"
        }
    }

    /// 删除点位
    func deletePoint(_ pointId: Int, from caseId: Int) {
        do {
            try service.deletePoint(pointId)
            casePoints[caseId]?.removeAll { $0.id == pointId }
        } catch {
            errorMessage = "删除点位失败: \(error.localizedDescription)"
        }
    }

    /// 更新点位名称
    func updatePointName(_ point: GeoPoint, newName: String) {
        var updatedPoint = point
        updatedPoint.name = newName

        do {
            try service.updatePoint(updatedPoint)
            loadPoints(for: point.caseId)
        } catch {
            errorMessage = "更新点位失败: \(error.localizedDescription)"
        }
    }

    // MARK: - UI Actions

    /// 切换案例展开状态
    func toggleCaseExpansion(_ caseId: Int) {
        if expandedCaseIds.contains(caseId) {
            expandedCaseIds.remove(caseId)
        } else {
            expandedCaseIds.insert(caseId)
            loadPoints(for: caseId)
        }
    }

    /// 清除错误消息
    func clearError() {
        errorMessage = nil
    }
}
