// SectorSearchConfig.swift
// 扇形搜索配置模型
// 见 PHASE_V3_SPEC.md

import Foundation

// MARK: - 扇形搜索常量

/// 扇形搜索距离限制
enum SectorSearchConstants {
    static let MIN_DISTANCE_METERS: Double = 100.0
    static let MAX_DISTANCE_METERS: Double = 5_000_000.0
    static let POI_MAX_DISTANCE_METERS: Double = 250_000.0
    static let MAX_POI_COUNT: Int = 50
}

// MARK: - 扇形模式

/// 扇形模式
enum SectorMode: Int, CaseIterable {
    case shan24 = 0   // 24山模式（15度）
    case bagua8 = 1   // 八方位模式（45度）

    var displayName: String {
        switch self {
        case .shan24: return "24山"
        case .bagua8: return "八方位"
        }
    }

    /// 扇形张角（度）
    var spreadAngle: Double {
        switch self {
        case .shan24: return 15.0
        case .bagua8: return 45.0
        }
    }
}

// MARK: - 距离单位

/// 距离单位
enum DistanceUnit: String, CaseIterable {
    case meter = "米"
    case kilometer = "千米"
}

// MARK: - 扇形方向

/// 扇形方向（统一24山和八方位）
enum SectorDirection: CaseIterable, Hashable {
    // 24山方向
    case zi, gui, chou, gen, yin, jia, mao, yi, chen
    case xun, si, bing, wu, ding, wei, kun, shen, geng
    case you, xin, xu, qian, hai, ren

    // 八方位方向
    case north, northeast, east, southeast
    case south, southwest, west, northwest

    /// 显示名称
    var displayName: String {
        switch self {
        // 24山
        case .zi: return "子"
        case .gui: return "癸"
        case .chou: return "丑"
        case .gen: return "艮"
        case .yin: return "寅"
        case .jia: return "甲"
        case .mao: return "卯"
        case .yi: return "乙"
        case .chen: return "辰"
        case .xun: return "巽"
        case .si: return "巳"
        case .bing: return "丙"
        case .wu: return "午"
        case .ding: return "丁"
        case .wei: return "未"
        case .kun: return "坤"
        case .shen: return "申"
        case .geng: return "庚"
        case .you: return "酉"
        case .xin: return "辛"
        case .xu: return "戌"
        case .qian: return "乾"
        case .hai: return "亥"
        case .ren: return "壬"
        // 八方位
        case .north: return "北"
        case .northeast: return "东北"
        case .east: return "东"
        case .southeast: return "东南"
        case .south: return "南"
        case .southwest: return "西南"
        case .west: return "西"
        case .northwest: return "西北"
        }
    }

    /// 中心角度（度，正北为0°，顺时针）
    var centerAngle: Double {
        switch self {
        // 24山：每山15度，从0度开始
        case .zi: return 0
        case .gui: return 15
        case .chou: return 30
        case .gen: return 45
        case .yin: return 60
        case .jia: return 75
        case .mao: return 90
        case .yi: return 105
        case .chen: return 120
        case .xun: return 135
        case .si: return 150
        case .bing: return 165
        case .wu: return 180
        case .ding: return 195
        case .wei: return 210
        case .kun: return 225
        case .shen: return 240
        case .geng: return 255
        case .you: return 270
        case .xin: return 285
        case .xu: return 300
        case .qian: return 315
        case .hai: return 330
        case .ren: return 345
        // 八方位：每方位45度
        case .north: return 0
        case .northeast: return 45
        case .east: return 90
        case .southeast: return 135
        case .south: return 180
        case .southwest: return 225
        case .west: return 270
        case .northwest: return 315
        }
    }

    /// 起始角度（度）
    /// 使用已有的Mountain.all和Trigram.all的角度数据
    var startAngle: Double {
        switch self {
        // 24山：从Mountain.all获取startAngle
        case .zi: return Mountain.all[0].startAngle      // 352.5
        case .gui: return Mountain.all[1].startAngle      // 7.5
        case .chou: return Mountain.all[2].startAngle     // 22.5
        case .gen: return Mountain.all[3].startAngle      // 37.5
        case .yin: return Mountain.all[4].startAngle      // 52.5
        case .jia: return Mountain.all[5].startAngle      // 67.5
        case .mao: return Mountain.all[6].startAngle      // 82.5
        case .yi: return Mountain.all[7].startAngle       // 97.5
        case .chen: return Mountain.all[8].startAngle     // 112.5
        case .xun: return Mountain.all[9].startAngle      // 127.5
        case .si: return Mountain.all[10].startAngle      // 142.5
        case .bing: return Mountain.all[11].startAngle    // 157.5
        case .wu: return Mountain.all[12].startAngle      // 172.5
        case .ding: return Mountain.all[13].startAngle    // 187.5
        case .wei: return Mountain.all[14].startAngle     // 202.5
        case .kun: return Mountain.all[15].startAngle     // 217.5
        case .shen: return Mountain.all[16].startAngle    // 232.5
        case .geng: return Mountain.all[17].startAngle    // 247.5
        case .you: return Mountain.all[18].startAngle     // 262.5
        case .xin: return Mountain.all[19].startAngle     // 277.5
        case .xu: return Mountain.all[20].startAngle      // 292.5
        case .qian: return Mountain.all[21].startAngle    // 307.5
        case .hai: return Mountain.all[22].startAngle     // 322.5
        case .ren: return Mountain.all[23].startAngle     // 337.5
        // 八方位：从Trigram.all获取startAngle
        case .north: return Trigram.all[0].startAngle     // 337.5
        case .northeast: return Trigram.all[1].startAngle // 22.5
        case .east: return Trigram.all[2].startAngle      // 67.5
        case .southeast: return Trigram.all[3].startAngle // 112.5
        case .south: return Trigram.all[4].startAngle     // 157.5
        case .southwest: return Trigram.all[5].startAngle // 202.5
        case .west: return Trigram.all[6].startAngle      // 247.5
        case .northwest: return Trigram.all[7].startAngle // 292.5
        }
    }

    /// 结束角度（度）
    var endAngle: Double {
        switch self {
        // 24山：从Mountain.all获取endAngle
        case .zi: return Mountain.all[0].endAngle      // 7.5
        case .gui: return Mountain.all[1].endAngle      // 22.5
        case .chou: return Mountain.all[2].endAngle     // 37.5
        case .gen: return Mountain.all[3].endAngle      // 52.5
        case .yin: return Mountain.all[4].endAngle      // 67.5
        case .jia: return Mountain.all[5].endAngle      // 82.5
        case .mao: return Mountain.all[6].endAngle      // 97.5
        case .yi: return Mountain.all[7].endAngle       // 112.5
        case .chen: return Mountain.all[8].endAngle     // 127.5
        case .xun: return Mountain.all[9].endAngle      // 142.5
        case .si: return Mountain.all[10].endAngle      // 157.5
        case .bing: return Mountain.all[11].endAngle    // 172.5
        case .wu: return Mountain.all[12].endAngle      // 187.5
        case .ding: return Mountain.all[13].endAngle    // 202.5
        case .wei: return Mountain.all[14].endAngle     // 217.5
        case .kun: return Mountain.all[15].endAngle     // 232.5
        case .shen: return Mountain.all[16].endAngle    // 247.5
        case .geng: return Mountain.all[17].endAngle    // 262.5
        case .you: return Mountain.all[18].endAngle     // 277.5
        case .xin: return Mountain.all[19].endAngle     // 292.5
        case .xu: return Mountain.all[20].endAngle      // 307.5
        case .qian: return Mountain.all[21].endAngle    // 322.5
        case .hai: return Mountain.all[22].endAngle     // 337.5
        case .ren: return Mountain.all[23].endAngle     // 352.5
        // 八方位：从Trigram.all获取endAngle
        case .north: return Trigram.all[0].endAngle     // 22.5
        case .northeast: return Trigram.all[1].endAngle // 67.5
        case .east: return Trigram.all[2].endAngle      // 112.5
        case .southeast: return Trigram.all[3].endAngle // 157.5
        case .south: return Trigram.all[4].endAngle     // 202.5
        case .southwest: return Trigram.all[5].endAngle // 247.5
        case .west: return Trigram.all[6].endAngle      // 292.5
        case .northwest: return Trigram.all[7].endAngle // 337.5
        }
    }

    /// 是否为24山方向
    var isShan24: Bool {
        switch self {
        case .zi, .gui, .chou, .gen, .yin, .jia, .mao, .yi, .chen,
             .xun, .si, .bing, .wu, .ding, .wei, .kun, .shen, .geng,
             .you, .xin, .xu, .qian, .hai, .ren:
            return true
        default:
            return false
        }
    }

    /// 是否为八方位方向
    var isBagua8: Bool {
        return !isShan24
    }

    /// 获取24山方向列表
    static var shan24Directions: [SectorDirection] {
        return [.zi, .gui, .chou, .gen, .yin, .jia, .mao, .yi, .chen,
                .xun, .si, .bing, .wu, .ding, .wei, .kun, .shen, .geng,
                .you, .xin, .xu, .qian, .hai, .ren]
    }

    /// 获取八方位方向列表
    static var bagua8Directions: [SectorDirection] {
        return [.north, .northeast, .east, .southeast,
                .south, .southwest, .west, .northwest]
    }
}

// MARK: - 扇形搜索配置

/// 扇形搜索配置
struct SectorSearchConfig {
    var mode: SectorMode = .shan24
    var direction: SectorDirection = .zi
    var poiKeyword: String?
    var distance: Double = 20.0
    var distanceUnit: DistanceUnit = .kilometer

    /// 距离转换为米
    var distanceInMeters: Double {
        switch distanceUnit {
        case .meter: return distance
        case .kilometer: return distance * 1000.0
        }
    }

    /// 距离是否有效（100米 - 5000千米）
    var isDistanceValid: Bool {
        let meters = distanceInMeters
        return meters >= SectorSearchConstants.MIN_DISTANCE_METERS
            && meters <= SectorSearchConstants.MAX_DISTANCE_METERS
    }

    /// 距离验证消息
    var distanceValidationMessage: String? {
        let meters = distanceInMeters
        if meters < SectorSearchConstants.MIN_DISTANCE_METERS {
            return "最小距离100米"
        }
        if meters > SectorSearchConstants.MAX_DISTANCE_METERS {
            return "最大距离5000千米（Mercator投影限制）"
        }
        return nil
    }

    /// 是否有POI关键词
    var hasKeyword: Bool {
        guard let keyword = poiKeyword else { return false }
        return !keyword.trimmingCharacters(in: .whitespaces).isEmpty
    }

    /// POI距离警告（超过250km时）
    var poiDistanceWarning: String? {
        guard hasKeyword else { return nil }
        if distanceInMeters > SectorSearchConstants.POI_MAX_DISTANCE_METERS {
            return "POI搜索限制在250km内"
        }
        return nil
    }

    /// 扇形起始角度
    var startAngle: Double {
        return direction.startAngle
    }

    /// 扇形结束角度
    var endAngle: Double {
        return direction.endAngle
    }

    /// 根据模式切换时重置方向
    mutating func resetDirectionForMode() {
        switch mode {
        case .shan24:
            if direction.isBagua8 {
                direction = .zi
            }
        case .bagua8:
            if direction.isShan24 {
                direction = .north
            }
        }
    }
}
