// SectorSearchViewModel.swift
// 扇形搜索视图模型
// 见 PHASE_V3_SPEC.md 1节

import Foundation
import Combine

/// 扇形搜索视图模型
class SectorSearchViewModel: ObservableObject {

    // MARK: - Published Properties

    /// 扇形搜索配置
    @Published var config: SectorSearchConfig = SectorSearchConfig()

    /// 是否已绘制扇形
    @Published var hasSectorDrawn: Bool = false

    /// 是否正在搜索
    @Published var isSearching: Bool = false

    /// 搜索结果消息（用于主地图显示）
    @Published var searchResultMessage: String?

    // MARK: - Private Properties

    /// 上次保留的配置（点击取消不保存，点击绘制/清除则保存）
    private var lastSavedConfig: SectorSearchConfig?

    // MARK: - Computed Properties

    /// 操作按钮标题
    var actionButtonTitle: String {
        config.hasKeyword ? "绘制并搜索" : "绘制区域"
    }

    /// 是否显示清除区域按钮（已绘制时显示）
    var showClearButton: Bool {
        hasSectorDrawn
    }

    /// 是否可以执行操作（距离验证通过）
    var canPerformAction: Bool {
        config.isDistanceValid
    }

    // MARK: - 操作方法

    /// 执行主操作：绘制扇形 + 可选POI搜索
    /// - Parameters:
    ///   - mapViewModel: 地图VM，执行实际绘制操作
    ///   - poiService: POI搜索服务
    func apply(mapViewModel: MapViewModel, poiService: POISearchService) async {
        guard config.isDistanceValid else { return }
        guard !Task.isCancelled else { return }

        // 保存配置（规格1.6：点击绘制时保存）
        lastSavedConfig = config

        let distanceInMeters = config.distanceInMeters

        await MainActor.run {
            isSearching = true
            searchResultMessage = nil
        }

        // 绘制扇形两翼
        await MainActor.run {
            mapViewModel.drawSectorWings(config: config)
            hasSectorDrawn = true
        }

        // POI搜索（若有关键词）
        if config.hasKeyword, let keyword = config.poiKeyword {
            // 搜索半径不超过POI最大限制250km
            let searchRadius = min(distanceInMeters, SectorSearchConstants.POI_MAX_DISTANCE_METERS)

            await MainActor.run {
                searchResultMessage = "正在搜索【\(keyword)】..."
            }

            do {
                let allPOIs = try await poiService.searchPOIAround(
                    keyword: keyword,
                    center: mapViewModel.sectorOrigin,
                    radiusMeters: searchRadius
                )

                // 检查 Task 是否被取消
                guard !Task.isCancelled else { return }

                // 扇形过滤
                let sectorPOIs = poiService.filterPOIsInSector(
                    origin: mapViewModel.sectorOrigin,
                    pois: allPOIs,
                    startAngle: config.startAngle,
                    endAngle: config.endAngle,
                    maxDistance: distanceInMeters
                )

                await MainActor.run {
                    isSearching = false
                    mapViewModel.showPOIMarkers(sectorPOIs)

                    // 生成结果消息
                    let distanceText = formatDistance(distanceInMeters)
                    if sectorPOIs.isEmpty {
                        searchResultMessage = "该区域内未找到【\(keyword)】"
                    } else {
                        searchResultMessage = "在\(distanceText)范围内找到\(sectorPOIs.count)个\(keyword)"
                    }
                }
            } catch {
                await MainActor.run {
                    isSearching = false
                    searchResultMessage = "搜索失败：\(error.localizedDescription)"
                }
            }
        } else {
            await MainActor.run {
                isSearching = false
            }
        }
    }

    /// 清除扇形和POI标记
    /// - Parameter mapViewModel: 地图VM
    func clearSector(mapViewModel: MapViewModel) {
        // 保存配置（规格1.6：点击清除时保存）
        lastSavedConfig = config

        mapViewModel.clearSector()
        hasSectorDrawn = false
        isSearching = false
        searchResultMessage = nil
    }

    /// 取消（不保存配置）
    func cancel() {
        // 恢复上次保存的配置（如果有的话）
        if let saved = lastSavedConfig {
            config = saved
        }
    }

    /// 打开Sheet时恢复上次配置
    func restoreLastConfig() {
        if let saved = lastSavedConfig {
            config = saved
        }
    }

    // MARK: - Private Methods

    /// 格式化距离文本
    private func formatDistance(_ meters: Double) -> String {
        if meters >= 1000 {
            return String(format: "%.0fkm", meters / 1000.0)
        } else {
            return String(format: "%.0f米", meters)
        }
    }
}
