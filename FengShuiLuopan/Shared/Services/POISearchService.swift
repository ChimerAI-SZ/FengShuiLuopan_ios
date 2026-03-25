// POISearchService.swift
// 高德POI搜索服务
// 见 PHASE_V3_SPEC.md 和 ARCHITECTURE.md 3.6节

import Foundation
import AMapSearchKit

/// POI搜索错误
enum POISearchError: LocalizedError {
    case searchFailed(String)
    case emptyResponse
    case cancelled
    case timeout

    var errorDescription: String? {
        switch self {
        case .searchFailed(let reason): return "搜索失败：\(reason)"
        case .emptyResponse: return "搜索返回空结果"
        case .cancelled: return "搜索已取消"
        case .timeout: return "搜索超时（5秒）"
        }
    }
}

/// POI搜索服务
/// 唯一依赖AMapSearchKit的文件，封装所有POI搜索逻辑
/// 使用withCheckedThrowingContinuation桥接AMapSearchDelegate到async/await
class POISearchService: NSObject {

    private let searcher: AMapSearchAPI

    /// 存储待完成的continuation（一次只有一个搜索）
    private var pendingContinuation: CheckedContinuation<[POIResult], Error>?

    /// 当前请求的 UUID（用于超时检查）
    private var currentRequestId: UUID?

    /// 原点坐标（用于计算POI的bearing和distance）
    private var searchOrigin: WGS84Coordinate?

    override init() {
        self.searcher = AMapSearchAPI()
        super.init()
        self.searcher.delegate = self
    }

    // MARK: - 圆形区域POI搜索

    /// 在指定圆形区域内搜索POI
    /// - Parameters:
    ///   - keyword: 搜索关键词
    ///   - center: 搜索中心（WGS-84坐标）
    ///   - radiusMeters: 搜索半径（米）
    /// - Returns: POI结果数组
    func searchPOIAround(keyword: String, center: WGS84Coordinate, radiusMeters: Double) async throws -> [POIResult] {
        // 取消旧请求
        if let old = pendingContinuation {
            pendingContinuation = nil
            old.resume(throwing: POISearchError.cancelled)
        }

        // WGS-84 → GCJ-02
        let gcj = CoordinateConverter.wgs84ToGcj02(center)
        self.searchOrigin = center

        let request = AMapPOIAroundSearchRequest()
        request.keywords = keyword
        request.location = AMapGeoPoint.location(
            withLatitude: CGFloat(gcj.latitude),
            longitude: CGFloat(gcj.longitude)
        )
        request.radius = Int(radiusMeters)

        let requestId = UUID()
        self.currentRequestId = requestId

        return try await withCheckedThrowingContinuation { continuation in
            self.pendingContinuation = continuation
            self.searcher.aMapPOIAroundSearch(request)

            // 设置 5 秒超时
            Task { [weak self] in
                try? await Task.sleep(nanoseconds: 5_000_000_000)
                guard let self = self, self.currentRequestId == requestId,
                      let c = self.pendingContinuation else { return }
                self.pendingContinuation = nil
                self.currentRequestId = nil
                c.resume(throwing: POISearchError.timeout)
            }
        }
    }

    // MARK: - 关键词搜索

    /// 关键词搜索POI（用于搜索Tab）
    /// - Parameter keyword: 搜索关键词
    /// - Returns: POI结果数组
    func searchPOIKeyword(keyword: String) async throws -> [POIResult] {
        // 取消旧请求
        if let old = pendingContinuation {
            pendingContinuation = nil
            old.resume(throwing: POISearchError.cancelled)
        }

        self.searchOrigin = nil  // 关键词搜索不需要原点

        let request = AMapPOIKeywordsSearchRequest()
        request.keywords = keyword

        let requestId = UUID()
        self.currentRequestId = requestId

        return try await withCheckedThrowingContinuation { continuation in
            self.pendingContinuation = continuation
            self.searcher.aMapPOIKeywordsSearch(request)

            // 设置 5 秒超时
            Task { [weak self] in
                try? await Task.sleep(nanoseconds: 5_000_000_000)
                guard let self = self, self.currentRequestId == requestId,
                      let c = self.pendingContinuation else { return }
                self.pendingContinuation = nil
                self.currentRequestId = nil
                c.resume(throwing: POISearchError.timeout)
            }
        }
    }

    // MARK: - 扇形过滤

    /// 从POI列表中过滤出扇形区域内的POI
    /// - Parameters:
    ///   - origin: 扇形中心点（WGS-84坐标）
    ///   - pois: POI列表
    ///   - startAngle: 扇形起始角度（度）
    ///   - endAngle: 扇形结束角度（度）
    ///   - maxDistance: 最大距离（米）
    /// - Returns: 过滤后的POI列表（最多50个，按距离排序）
    func filterPOIsInSector(
        origin: WGS84Coordinate,
        pois: [POIResult],
        startAngle: Double,
        endAngle: Double,
        maxDistance: Double
    ) -> [POIResult] {
        let filtered = pois.filter { poi in
            // 1. 计算原点到POI的Rhumb Line方位角
            let bearing = FengShuiEngine.calculateRhumbBearing(from: origin, to: poi.coordinate)

            // 2. 判断方位角是否在扇形范围内
            let inAngle = isAngleInRange(bearing, start: startAngle, end: endAngle)

            // 3. 判断距离是否在范围内
            let distance = FengShuiEngine.calculateVincentyDistance(from: origin, to: poi.coordinate)

            return inAngle && distance <= maxDistance
        }

        // 按距离排序，取前50个
        return Array(filtered.sorted { $0.distance < $1.distance }.prefix(50))
    }

    // MARK: - 结果转换

    /// 将高德AMapPOI转换为POIResult（GCJ-02 → WGS-84）
    private func convertPOIs(_ amapPOIs: [AMapPOI], origin: WGS84Coordinate?) -> [POIResult] {
        return amapPOIs.compactMap { poi in
            guard let location = poi.location else { return nil }

            // GCJ-02 → WGS-84
            let gcjCoord = WGS84Coordinate(
                latitude: Double(location.latitude),
                longitude: Double(location.longitude)
            )
            let wgsCoord = CoordinateConverter.gcj02ToWgs84(gcjCoord)

            // 计算distance和bearing（如果有原点）
            let distance: Double
            let bearing: Double
            if let orig = origin {
                distance = FengShuiEngine.calculateVincentyDistance(from: orig, to: wgsCoord)
                bearing = FengShuiEngine.calculateRhumbBearing(from: orig, to: wgsCoord)
            } else {
                distance = Double(poi.distance)
                bearing = 0
            }

            return POIResult(
                id: poi.uid ?? UUID().uuidString,
                name: poi.name ?? "",
                address: poi.address ?? "",
                coordinate: wgsCoord,
                distance: distance,
                bearing: bearing,
                category: poi.type
            )
        }
    }

    // MARK: - 角度范围判断

    /// 判断角度是否在指定范围内（处理跨0°情况）
    private func isAngleInRange(_ angle: Double, start: Double, end: Double) -> Bool {
        if start <= end {
            return angle >= start && angle <= end
        } else {
            // 跨越0°的范围，如 [350°, 10°]
            return angle >= start || angle <= end
        }
    }
}

// MARK: - AMapSearchDelegate

extension POISearchService: AMapSearchDelegate {

    /// POI搜索回调（圆形和关键词均通过此回调返回）
    func onPOISearchDone(_ request: AMapPOISearchBaseRequest!, response: AMapPOISearchResponse!) {
        guard let continuation = pendingContinuation else { return }
        pendingContinuation = nil
        currentRequestId = nil

        if let pois = response?.pois, !pois.isEmpty {
            let results = convertPOIs(pois, origin: searchOrigin)
            continuation.resume(returning: results)
        } else {
            continuation.resume(returning: [])
        }
    }

    /// 搜索请求失败回调
    func aMapSearchRequest(_ request: Any!, didFailWithError error: Error!) {
        guard let continuation = pendingContinuation else { return }
        pendingContinuation = nil
        currentRequestId = nil
        continuation.resume(throwing: POISearchError.searchFailed(error?.localizedDescription ?? "未知错误"))
    }
}
