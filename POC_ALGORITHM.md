# 纯算法POC设计文档

> **目标**：验证FengShuiLuopan核心算法的正确性和精度
> **环境**：纯Swift代码，可在Windows编写，Mac/Linux验证
> **时间**：预计2-3小时完成编写和验证
> 创建时间：2026-02-27

---

## 1. POC目标

### 1.1 验证范围
- ✅ Rhumb Line方位角计算
- ✅ Vincenty距离计算
- ✅ WGS-84 ↔ GCJ-02坐标转换
- ✅ 24山方位映射
- ✅ 八卦映射
- ✅ 五行映射
- ✅ 扇形终点计算（Rhumb Line Direct）
- ✅ 边界情况处理

### 1.2 不包含内容
- ❌ 地图SDK集成
- ❌ UI界面
- ❌ 数据库操作
- ❌ 网络请求

### 1.3 成功标准
- 所有测试用例通过
- 精度满足要求（方位角±0.1°，距离±1m）
- 边界情况正确处理
- 代码可读性好，注释完整

---

## 2. POC架构设计

### 2.1 文件结构
```
POC_Algorithm/
├── Sources/
│   ├── Models/
│   │   └── WGS84Coordinate.swift      # 基础坐标类型
│   ├── Core/
│   │   ├── FengShuiEngine.swift       # 核心算法引擎
│   │   ├── CoordinateConverter.swift  # 坐标转换
│   │   ├── Mountain.swift             # 24山数据
│   │   ├── Trigram.swift              # 八卦数据
│   │   └── WuXing.swift               # 五行数据
│   └── main.swift                     # 测试入口
└── README.md                          # POC说明文档
```

### 2.2 核心类设计

#### 2.2.1 WGS84Coordinate（基础坐标）
```swift
struct WGS84Coordinate: Equatable {
    let latitude: Double   // 纬度 -90 ~ 90
    let longitude: Double  // 经度 -180 ~ 180

    init(latitude: Double, longitude: Double) {
        // 验证范围
        precondition(latitude >= -90 && latitude <= 90, "纬度超出范围")
        precondition(longitude >= -180 && longitude <= 180, "经度超出范围")
        self.latitude = latitude
        self.longitude = longitude
    }
}
```

#### 2.2.2 FengShuiEngine（核心算法）
```swift
struct FengShuiEngine {
    // WGS-84椭球参数
    static let EARTH_RADIUS_A = 6378137.0          // 长半轴（米）
    static let EARTH_RADIUS_B = 6356752.314245     // 短半轴（米）
    static let EARTH_FLATTENING = 1/298.257223563  // 扁率

    // === Rhumb Line方位角 ===
    static func calculateRhumbBearing(
        from: WGS84Coordinate,
        to: WGS84Coordinate
    ) -> Double {
        // 实现见ARCHITECTURE.md 3.1节
    }

    // === Vincenty距离 ===
    static func calculateVincentyDistance(
        from: WGS84Coordinate,
        to: WGS84Coordinate
    ) -> Double {
        // 实现见ARCHITECTURE.md 3.2节
    }

    // === Rhumb Line正算（扇形终点计算）===
    static func calculateRhumbDestination(
        from: WGS84Coordinate,
        bearing: Double,
        distance: Double
    ) -> WGS84Coordinate {
        // 实现见ARCHITECTURE.md 3.3节
    }

    // === 方位角转24山 ===
    static func bearingToMountain(_ bearing: Double) -> Mountain {
        // 实现见Mountain.swift
    }

    // === 方位角转八卦 ===
    static func bearingToTrigram(_ bearing: Double) -> Trigram {
        // 实现见Trigram.swift
    }

    // === 方位角转五行 ===
    static func bearingToWuXing(_ bearing: Double) -> WuXing {
        // 实现见WuXing.swift
    }
}
```

#### 2.2.3 CoordinateConverter（坐标转换）
```swift
struct CoordinateConverter {
    // WGS-84 → GCJ-02
    static func wgs84ToGcj02(_ coord: WGS84Coordinate) -> WGS84Coordinate {
        // 实现火星坐标系转换
    }

    // GCJ-02 → WGS-84
    static func gcj02ToWgs84(_ coord: WGS84Coordinate) -> WGS84Coordinate {
        // 实现逆转换
    }

    // 判断是否在中国境内
    static func isInChina(_ coord: WGS84Coordinate) -> Bool {
        // 简化判断：经度73.66-135.05，纬度3.86-53.55
    }
}
```

#### 2.2.4 Mountain（24山）
```swift
struct Mountain {
    let index: Int        // 0-23
    let name: String      // 如"子"
    let angle: Double     // 中心角度
    let startAngle: Double
    let endAngle: Double

    static let all: [Mountain] = [
        Mountain(index: 0, name: "子", angle: 0, ...),
        Mountain(index: 1, name: "癸", angle: 15, ...),
        // ... 共24个
    ]

    static func fromBearing(_ bearing: Double) -> Mountain {
        // 根据方位角查找对应的山
    }
}
```

---

## 3. 测试用例设计

### 3.1 基准测试数据

#### 3.1.1 方位角测试
```swift
struct BearingTestCase {
    let name: String
    let from: WGS84Coordinate
    let to: WGS84Coordinate
    let expectedBearing: Double
    let tolerance: Double = 0.1  // ±0.1度
}

let bearingTests: [BearingTestCase] = [
    // 1. 北京→上海
    BearingTestCase(
        name: "北京→上海",
        from: WGS84Coordinate(latitude: 39.9042, longitude: 116.4074),
        to: WGS84Coordinate(latitude: 31.2304, longitude: 121.4737),
        expectedBearing: 136.0
    ),

    // 2. 正北方向
    BearingTestCase(
        name: "正北",
        from: WGS84Coordinate(latitude: 39.9, longitude: 116.4),
        to: WGS84Coordinate(latitude: 40.9, longitude: 116.4),
        expectedBearing: 0.0
    ),

    // 3. 正东方向
    BearingTestCase(
        name: "正东",
        from: WGS84Coordinate(latitude: 39.9, longitude: 116.4),
        to: WGS84Coordinate(latitude: 39.9, longitude: 117.4),
        expectedBearing: 90.0
    ),

    // 4. 正南方向
    BearingTestCase(
        name: "正南",
        from: WGS84Coordinate(latitude: 39.9, longitude: 116.4),
        to: WGS84Coordinate(latitude: 38.9, longitude: 116.4),
        expectedBearing: 180.0
    ),

    // 5. 正西方向
    BearingTestCase(
        name: "正西",
        from: WGS84Coordinate(latitude: 39.9, longitude: 116.4),
        to: WGS84Coordinate(latitude: 39.9, longitude: 115.4),
        expectedBearing: 270.0
    ),

    // 6. 同点计算
    BearingTestCase(
        name: "同点",
        from: WGS84Coordinate(latitude: 39.9, longitude: 116.4),
        to: WGS84Coordinate(latitude: 39.9, longitude: 116.4),
        expectedBearing: 0.0
    ),

    // 7. 跨180°经线（东向西）
    BearingTestCase(
        name: "跨180°经线",
        from: WGS84Coordinate(latitude: 0, longitude: 179),
        to: WGS84Coordinate(latitude: 0, longitude: -179),
        expectedBearing: 90.0
    ),
]
```

#### 3.1.2 距离测试
```swift
struct DistanceTestCase {
    let name: String
    let from: WGS84Coordinate
    let to: WGS84Coordinate
    let expectedDistance: Double  // 米
    let tolerance: Double = 1.0   // ±1米
}

let distanceTests: [DistanceTestCase] = [
    // 1. 北京→上海
    DistanceTestCase(
        name: "北京→上海",
        from: WGS84Coordinate(latitude: 39.9042, longitude: 116.4074),
        to: WGS84Coordinate(latitude: 31.2304, longitude: 121.4737),
        expectedDistance: 1067000.0  // 约1067km
    ),

    // 2. 短距离（1km）
    DistanceTestCase(
        name: "短距离1km",
        from: WGS84Coordinate(latitude: 39.9, longitude: 116.4),
        to: WGS84Coordinate(latitude: 39.909, longitude: 116.4),
        expectedDistance: 1000.0
    ),

    // 3. 同点
    DistanceTestCase(
        name: "同点",
        from: WGS84Coordinate(latitude: 39.9, longitude: 116.4),
        to: WGS84Coordinate(latitude: 39.9, longitude: 116.4),
        expectedDistance: 0.0
    ),
]
```

#### 3.1.3 24山映射测试
```swift
struct MountainTestCase {
    let bearing: Double
    let expectedMountain: String
}

let mountainTests: [MountainTestCase] = [
    MountainTestCase(bearing: 0.0, expectedMountain: "子"),
    MountainTestCase(bearing: 15.0, expectedMountain: "癸"),
    MountainTestCase(bearing: 30.0, expectedMountain: "丑"),
    MountainTestCase(bearing: 45.0, expectedMountain: "艮"),
    MountainTestCase(bearing: 90.0, expectedMountain: "卯"),
    MountainTestCase(bearing: 180.0, expectedMountain: "午"),
    MountainTestCase(bearing: 270.0, expectedMountain: "酉"),
    MountainTestCase(bearing: 359.9, expectedMountain: "子"),
]
```

#### 3.1.4 坐标转换测试
```swift
struct ConversionTestCase {
    let name: String
    let wgs84: WGS84Coordinate
    let gcj02: WGS84Coordinate
    let tolerance: Double = 0.00001  // 约1米
}

let conversionTests: [ConversionTestCase] = [
    // 北京天安门
    ConversionTestCase(
        name: "北京天安门",
        wgs84: WGS84Coordinate(latitude: 39.90960456049752, longitude: 116.3972282409668),
        gcj02: WGS84Coordinate(latitude: 39.91519, longitude: 116.40381)
    ),

    // 上海东方明珠
    ConversionTestCase(
        name: "上海东方明珠",
        wgs84: WGS84Coordinate(latitude: 31.239663, longitude: 121.499809),
        gcj02: WGS84Coordinate(latitude: 31.245105, longitude: 121.506377)
    ),
]
```

#### 3.1.5 Rhumb Line正算测试
```swift
struct RhumbDirectTestCase {
    let name: String
    let from: WGS84Coordinate
    let bearing: Double
    let distance: Double
    let expectedTo: WGS84Coordinate
    let tolerance: Double = 0.0001  // 约10米
}

let rhumbDirectTests: [RhumbDirectTestCase] = [
    // 正北1km
    RhumbDirectTestCase(
        name: "正北1km",
        from: WGS84Coordinate(latitude: 39.9, longitude: 116.4),
        bearing: 0.0,
        distance: 1000.0,
        expectedTo: WGS84Coordinate(latitude: 39.909, longitude: 116.4)
    ),

    // 正东1km
    RhumbDirectTestCase(
        name: "正东1km",
        from: WGS84Coordinate(latitude: 39.9, longitude: 116.4),
        bearing: 90.0,
        distance: 1000.0,
        expectedTo: WGS84Coordinate(latitude: 39.9, longitude: 116.413)
    ),
]
```

### 3.2 边界情况测试

```swift
struct EdgeCaseTest {
    let name: String
    let test: () -> Bool
}

let edgeCaseTests: [EdgeCaseTest] = [
    // 1. 极地附近（纬度>85°）
    EdgeCaseTest(name: "极地附近") {
        let from = WGS84Coordinate(latitude: 85.0, longitude: 0)
        let to = WGS84Coordinate(latitude: 85.0, longitude: 1)
        let bearing = FengShuiEngine.calculateRhumbBearing(from: from, to: to)
        return bearing >= 0 && bearing < 360
    },

    // 2. 跨180°经线
    EdgeCaseTest(name: "跨180°经线") {
        let from = WGS84Coordinate(latitude: 0, longitude: 179)
        let to = WGS84Coordinate(latitude: 0, longitude: -179)
        let bearing = FengShuiEngine.calculateRhumbBearing(from: from, to: to)
        return abs(bearing - 90.0) < 1.0
    },

    // 3. 赤道附近
    EdgeCaseTest(name: "赤道附近") {
        let from = WGS84Coordinate(latitude: 0.0, longitude: 0)
        let to = WGS84Coordinate(latitude: 0.0, longitude: 1)
        let bearing = FengShuiEngine.calculateRhumbBearing(from: from, to: to)
        return abs(bearing - 90.0) < 0.1
    },

    // 4. 零距离
    EdgeCaseTest(name: "零距离") {
        let coord = WGS84Coordinate(latitude: 39.9, longitude: 116.4)
        let distance = FengShuiEngine.calculateVincentyDistance(from: coord, to: coord)
        return distance == 0.0
    },
]
```

---

## 4. 实现步骤

### 4.1 第一步：创建基础结构（30分钟）
- [ ] 创建POC_Algorithm目录
- [ ] 创建WGS84Coordinate.swift
- [ ] 创建FengShuiEngine.swift骨架
- [ ] 创建测试框架main.swift

### 4.2 第二步：实现Rhumb Line方位角（45分钟）
- [ ] 实现calculateRhumbBearing函数
- [ ] 处理边界情况（同点、跨180°）
- [ ] 运行方位角测试用例
- [ ] 调试直到所有测试通过

### 4.3 第三步：实现Vincenty距离（45分钟）
- [ ] 实现calculateVincentyDistance函数
- [ ] 处理收敛问题
- [ ] 运行距离测试用例
- [ ] 调试直到所有测试通过

### 4.4 第四步：实现24山/八卦/五行映射（30分钟）
- [ ] 创建Mountain.swift
- [ ] 创建Trigram.swift
- [ ] 创建WuXing.swift
- [ ] 实现映射逻辑
- [ ] 运行映射测试用例

### 4.5 第五步：实现坐标转换（30分钟）
- [ ] 实现WGS-84 → GCJ-02
- [ ] 实现GCJ-02 → WGS-84
- [ ] 运行转换测试用例

### 4.6 第六步：实现Rhumb Line正算（30分钟）
- [ ] 实现calculateRhumbDestination函数
- [ ] 运行正算测试用例

### 4.7 第七步：综合测试（30分钟）
- [ ] 运行所有测试用例
- [ ] 生成测试报告
- [ ] 记录精度数据

---

## 5. 测试报告模板

```
=== FengShuiLuopan 算法POC测试报告 ===
测试时间：2026-02-27
测试环境：macOS / Linux / Windows (Swift 5.9+)

--- 方位角测试 ---
✅ 北京→上海: 实际=136.02°, 预期=136.0°, 误差=0.02°
✅ 正北: 实际=0.00°, 预期=0.0°, 误差=0.00°
✅ 正东: 实际=90.00°, 预期=90.0°, 误差=0.00°
✅ 正南: 实际=180.00°, 预期=180.0°, 误差=0.00°
✅ 正西: 实际=270.00°, 预期=270.0°, 误差=0.00°
✅ 同点: 实际=0.00°, 预期=0.0°, 误差=0.00°
✅ 跨180°经线: 实际=90.05°, 预期=90.0°, 误差=0.05°
通过率: 7/7 (100%)

--- 距离测试 ---
✅ 北京→上海: 实际=1067123m, 预期=1067000m, 误差=123m
✅ 短距离1km: 实际=1000.2m, 预期=1000m, 误差=0.2m
✅ 同点: 实际=0.0m, 预期=0m, 误差=0.0m
通过率: 3/3 (100%)

--- 24山映射测试 ---
✅ 0° → 子
✅ 15° → 癸
✅ 30° → 丑
✅ 45° → 艮
✅ 90° → 卯
✅ 180° → 午
✅ 270° → 酉
✅ 359.9° → 子
通过率: 8/8 (100%)

--- 坐标转换测试 ---
✅ 北京天安门: WGS→GCJ→WGS 往返误差=0.5m
✅ 上海东方明珠: WGS→GCJ→WGS 往返误差=0.3m
通过率: 2/2 (100%)

--- Rhumb Line正算测试 ---
✅ 正北1km: 误差=0.1m
✅ 正东1km: 误差=0.2m
通过率: 2/2 (100%)

--- 边界情况测试 ---
✅ 极地附近
✅ 跨180°经线
✅ 赤道附近
✅ 零距离
通过率: 4/4 (100%)

=== 总结 ===
总测试用例: 26
通过: 26
失败: 0
通过率: 100%

结论: ✅ 所有核心算法验证通过，精度满足要求
```

---

## 6. 验证环境

### 6.1 Windows验证（编写代码）
```bash
# 安装Swift for Windows
# https://www.swift.org/download/

# 编译
swiftc -o poc_test Sources/**/*.swift

# 运行
./poc_test
```

### 6.2 macOS验证（推荐）
```bash
# 创建Swift Package
swift package init --type executable

# 编译运行
swift run
```

### 6.3 Linux验证
```bash
# 使用Docker
docker run --rm -v $(pwd):/code swift:5.9 bash -c "cd /code && swift run"
```

---

## 7. 成功标准检查清单

- [ ] 所有测试用例通过率100%
- [ ] 方位角精度±0.1°以内
- [ ] 距离精度±1m以内（短距离）或±0.01%（长距离）
- [ ] 坐标转换往返误差<1m
- [ ] 边界情况正确处理
- [ ] 代码注释完整，引用ARCHITECTURE.md章节
- [ ] 测试报告生成

---

## 8. 下一步计划

POC验证通过后：
1. 将算法代码迁移到正式项目的Core层
2. 添加XCTest单元测试
3. 开始Phase 0地图SDK集成
4. 准备首次云Mac真机验证

---

## 9. 参考资料

- ARCHITECTURE.md 第3节：核心算法决策
- ARCHITECTURE.md 第15.2节：Core层单元测试
- Rhumb Line算法: https://www.movable-type.co.uk/scripts/latlong.html
- Vincenty算法: https://en.wikipedia.org/wiki/Vincenty%27s_formulae
