# FengShuiLuopan iOS - 技术架构文档（唯一真相）

> **本文档是项目的"宪法"，所有开发决策以此为准。**
> 任何技术选型变更必须先更新本文档，再修改代码。
> 最后更新：2026-02-26

---

## 1. 项目概述

- **项目名称**：FengShuiLuopan（堪舆罗盘）
- **功能定位**：基于24山的专业风水方位测量工具
- **核心功能**：多原点多终点测量、扇形区域搜索、生活圈分析
- **前身**：Flutter版 luopan_app（V0已完成基础功能）

---

## 2. 技术选型矩阵

| 技术领域 | 选型 | 版本/备注 |
|---------|------|----------|
| 语言 | Swift | 5.9+ |
| UI框架 | SwiftUI | iOS 16.0+ |
| 最低iOS版本 | **iOS 16.0** | iPhone 8+，覆盖~70%用户，测试机iPhone X支持 |
| 状态管理 | @ObservableObject + MVVM | 清晰分层，iOS 16兼容 |
| 导航 | NavigationStack | iOS 16新API，替代NavigationView |
| 数据库 | SQLite.swift | 轻量、SQL直观、无代码生成 |
| 依赖管理 | **CocoaPods** | 高德SDK官方主推，稳定性优先 |
| 地图SDK | 高德地图iOS SDK (3D) | CocoaPods集成，9.x版本 |
| 地图抽象 | MapControllerProtocol | 预留Google Maps扩展（V5+） |
| 坐标系 | WGS-84统一存储 | 转换在地图抽象层内部完成 |
| 方位角计算 | **Rhumb Line（恒向线）** | 角度对称性好，风水语义正确 |
| 距离计算 | **Vincenty（Geodesic）** | 高精度，全距离范围适用 |
| 扇形终点计算 | Rhumb Line | 与方位角一致，扇形边界是直线 |
| 定位 | Core Location | 原生GPS |
| 北方指示器 | 地图SDK回调（mapView heading） | 跟随地图旋转状态，非物理指南针 |
| 网络请求 | URLSession | 原生，无额外依赖 |
| 高德API Key | `16d5c89d0a14758cae55c218e2bd3322` | 已有 |

### 2.1 依赖清单与版本锁定

**Podfile 依赖：**

| 依赖 | 版本 | 用途 |
|------|------|------|
| AMapMaps | ~> 9.7 | 高德3D地图SDK |
| AMapLocation | ~> 2.10 | 高德定位SDK（可选，也可用Core Location） |
| AMapSearch | ~> 9.5 | 高德POI搜索（Phase 3扇形搜索用） |

**SPM 依赖：**

| 依赖 | 版本 | 用途 |
|------|------|------|
| SQLite.swift | ~> 0.15.0 | 本地数据库 |

**说明：**
- 高德SDK通过CocoaPods管理（官方推荐）
- SQLite.swift通过SPM管理（纯Swift库，SPM支持好）
- 两种包管理器可以在同一项目中共存
- 版本号使用 `~>` 锁定主版本，允许补丁更新
- 每次云Mac验证时，记录实际安装的版本号到 `Podfile.lock`

---

## 3. 核心算法决策

### 3.1 方位角：Rhumb Line（恒向线）

**选择理由（来自大佬参考文档）：**
- 角度完美对称：`bearing_AB + bearing_BA = 360°`
- 24山方位正对：原点终点互换后，山位索引差正好12
- 四正方向正交：子午卯酉成90度直角
- 连线是直线：在Mercator地图上与罗盘刻度线完美对齐

**Rhumb Line方位角公式：**
```
Δφ' = ln(tan(π/4 + φ2/2) / tan(π/4 + φ1/2))  // Mercator纬度差
Δλ = λ2 - λ1                                     // 经度差
bearing = atan2(Δλ, Δφ')                          // 方位角
```

**与Flutter版的区别：** Flutter版使用Vincenty（Geodesic）计算方位角，iOS版改用Rhumb Line。这是有意的设计改进，不是bug。

### 3.2 距离：Vincenty（Geodesic）

**选择理由：**
- 椭球体模型，精度达毫米级
- 全距离范围适用（近距离和远距离都准确）
- Rhumb Line距离在长距离时误差显著

**WGS-84椭球参数：**
```
a = 6378137.0          // 长半轴（米）
b = 6356752.314245     // 短半轴（米）
f = 1/298.257223563    // 扁率
```

### 3.3 扇形终点计算：Rhumb Line Direct

**选择理由：**
- 扇形边界应与罗盘刻度线对齐
- 使用Rhumb Line正算（给定起点、方位角、距离→终点）
- 保证扇形在Mercator地图上显示为直线边界

**Rhumb Line正算公式：**
```
δ = d / a                                          // 角距离（d=距离，a=地球长半轴）
φ2 = φ1 + δ·cos(bearing)                           // 目标纬度
Δφ' = ln(tan(π/4 + φ2/2) / tan(π/4 + φ1/2))      // Mercator纬度差
q = (Δφ' ≠ 0) ? (φ2 - φ1)/Δφ' : cos(φ1)          // 修正系数
Δλ = δ·sin(bearing) / q                            // 经度差
λ2 = λ1 + Δλ                                       // 目标经度
```

### 3.4 扇形多边形生成算法

**输入参数：**
- `center`: WGS84Coordinate — 扇形中心点（原点）
- `azimuth`: Double — 扇形中心方位角（度）
- `radius`: Double — 扇形半径（米）
- `spread`: Double — 扇形张角（度），如24山模式=15°，八方位模式=45°

**生成步骤：**
1. 计算起始角 `startAngle = azimuth - spread/2`
2. 计算结束角 `endAngle = azimuth + spread/2`
3. 将弧线等分为N段（默认N=36，保证视觉平滑）
4. 生成顶点序列：`[center, arc_point_0, arc_point_1, ..., arc_point_N, center]`
5. 每个弧线点通过 Rhumb Line正算 计算：`destinationPoint(center, angle_i, radius)`

**搜索距离限制：**
- 最小：0.1 km
- 最大：5000 km（扇形绘制）
- POI搜索限制：≤250 km（高德API限制）

### 3.5 点在扇形内检测

**算法：**
1. 计算 `center` 到 `point` 的Vincenty距离，若 > radius 则不在扇形内
2. 计算 `center` 到 `point` 的Rhumb Line方位角
3. 判断方位角是否在 `[startAngle, endAngle]` 范围内（处理跨0°情况）

### 3.6 扇形区域POI搜索过滤算法

高德POI搜索返回的是圆形区域内的结果，需要二次过滤为扇形区域内的POI。

```swift
func filterPOIsInSector(
    origin: WGS84Coordinate,
    pois: [POIResult],
    startAngle: Double,    // 扇形起始角度
    endAngle: Double,      // 扇形结束角度
    maxDistance: Double     // 最大距离（米）
) -> [POIResult] {
    return pois.filter { poi in
        // 1. 计算原点到POI的Rhumb Line方位角
        let bearing = FengShuiEngine.calculateRhumbBearing(from: origin, to: poi.coordinate)
        // 2. 判断方位角是否在扇形范围内
        let inAngle = isAngleInRange(bearing, start: startAngle, end: endAngle)
        // 3. 判断距离是否在范围内
        let distance = FengShuiEngine.calculateVincentyDistance(from: origin, to: poi.coordinate)
        return inAngle && distance <= maxDistance
    }
}

// 处理跨0度的角度范围判断
func isAngleInRange(_ angle: Double, start: Double, end: Double) -> Bool {
    if start <= end {
        return angle >= start && angle <= end
    } else {
        // 跨越0度，如 [350°, 10°]
        return angle >= start || angle <= end
    }
}
```

**八方位到24山映射：**

八方位选择时，自动扩展为对应的3个24山（45°范围）：

| 八卦 | 方向 | 对应24山 | 角度范围 |
|------|------|---------|---------|
| 坎 | 北 | 子、癸、丑 | 337.5°-22.5° |
| 艮 | 东北 | 艮、寅、甲 | 22.5°-67.5° |
| 震 | 东 | 卯、乙、辰 | 67.5°-112.5° |
| 巽 | 东南 | 巽、巳、丙 | 112.5°-157.5° |
| 离 | 南 | 午、丁、未 | 157.5°-202.5° |
| 坤 | 西南 | 坤、申、庚 | 202.5°-247.5° |
| 兑 | 西 | 酉、辛、戌 | 247.5°-292.5° |
| 乾 | 西北 | 乾、亥、壬 | 292.5°-337.5° |

---

## 4. 架构设计

### 4.1 分层架构

```
┌─────────────────────────────────────────┐
│  UI Layer (SwiftUI Views)               │
│  - MapView, NorthIndicator, Panels       │
├─────────────────────────────────────────┤
│  ViewModel Layer (ObservableObject)      │
│  - MapViewModel, CaseViewModel          │
├─────────────────────────────────────────┤
│  Service Layer                          │
│  - LocationService, MapService           │
│  - MapControllerProtocol                │
├─────────────────────────────────────────┤
│  Core Layer (纯Swift，无UI/SDK依赖)      │
│  - FengShuiEngine, CoordinateConverter  │
│  - WGS84Coordinate (基础坐标类型)        │
├─────────────────────────────────────────┤
│  Data Layer                             │
│  - Models, Repositories, SQLite         │
└─────────────────────────────────────────┘
```

**依赖规则：上层可依赖下层，下层不可依赖上层。Core层不依赖任何外部SDK。**

### 4.2 地图抽象层（双SDK预留架构）

#### 4.2.1 整体架构

```
┌──────────────────────────────────────────────────────┐
│  业务层 (ViewModel / Service)                         │
│  只依赖 MapControllerProtocol，不感知底层SDK           │
├──────────────────────────────────────────────────────┤
│  MapSDKManager (SDK生命周期管理 + 切换调度)            │
│  - 持有当前活跃的 MapControllerProtocol 实例           │
│  - 根据 MapSDKPreference 决定使用哪个实现              │
│  - 处理SDK切换时的状态迁移                             │
├──────────────┬───────────────────────────────────────┤
│  GaodeMap     │  GoogleMap                            │
│  Controller   │  Controller                           │
│  (V1实现)     │  (V5+实现)                             │
│  WGS→GCJ-02  │  WGS→WGS(直传)                        │
├──────────────┴───────────────────────────────────────┤
│  RegionDetector (区域检测服务，V5+实现)                 │
│  - GPS位置判断国内/海外                                │
│  - SIM卡运营商信息辅助判断                             │
│  - 跨境检测与切换提示                                  │
└──────────────────────────────────────────────────────┘
```

#### 4.2.2 MapControllerProtocol（核心接口，V1就定义好）

```swift
protocol MapControllerProtocol {
    // === 相机控制 (V1) ===
    func moveCamera(to: WGS84Coordinate, zoom: Float, animated: Bool)
    func getCurrentCenter() -> WGS84Coordinate
    func getCurrentZoom() -> Float

    // === 标记点 (V1) ===
    func addMarker(id: String, at: WGS84Coordinate, icon: MarkerIcon) -> String
    func removeMarker(id: String)
    func removeAllMarkers()

    // === 覆盖层 (V2+) ===
    func addSectorOverlay(id: String, center: WGS84Coordinate,
                          radiusMeters: Double, startAngle: Double,
                          endAngle: Double, style: OverlayStyle)
    func addPolyline(id: String, points: [WGS84Coordinate], style: PolylineStyle) -> String
    func removeOverlay(id: String)
    func removeAllOverlays()

    // === 地理编码 (V4+) ===
    func geocode(address: String) async throws -> [GeocodingResult]
    func reverseGeocode(coordinate: WGS84Coordinate) async throws -> String?

    // === 地图类型 ===
    func setMapType(_ type: MapLayerType)
    func getMapType() -> MapLayerType

    // === 屏幕坐标转换 ===
    func screenToCoordinate(_ point: CGPoint) -> WGS84Coordinate?
    func coordinateToScreen(_ coord: WGS84Coordinate) -> CGPoint?

    // === 回调 ===
    var onMapTap: ((WGS84Coordinate) -> Void)? { get set }
    var onMarkerTap: ((String) -> Void)? { get set }
    var onCameraMove: ((WGS84Coordinate, Float) -> Void)? { get set }

    // === SDK标识（V5+用于切换判断）===
    var sdkType: MapSDKType { get }
}
```

**版本实现策略：**
- V1：实现相机控制、标记点、地图类型、屏幕坐标转换、回调
- V2：加入覆盖层（扇形+连线）
- V4：加入地理编码
- Protocol签名从V1到V4不变，各版本只需在GaodeMapController中逐步实现

#### 4.2.3 MapSDKManager（SDK管理器，V1实现骨架）

```swift
class MapSDKManager: ObservableObject {
    @Published var activeController: MapControllerProtocol

    // V1: 直接返回GaodeMapController，无切换逻辑
    // V5: 根据preference和regionDetector决定使用哪个SDK
    func resolveController(preference: MapSDKPreference) -> MapControllerProtocol
}
```

**V1阶段**：MapSDKManager只是GaodeMapController的简单包装，不实现切换逻辑。
**V5阶段**：加入SDK切换、状态迁移、区域检测。

#### 4.2.4 SDK选择枚举与用户设置（V1就定义好）

```swift
enum MapSDKType {
    case gaode       // 高德地图
    case google      // Google Maps（V5+）
}

enum MapSDKPreference: Int {
    case auto = 0    // 自动检测（根据GPS/SIM卡选择最佳SDK）
    case gaode = 1   // 强制高德
    case google = 2  // 强制Google Maps
}
```

#### 4.2.5 V5用户设置界面预留

设置页面将包含两个地图相关选项：

**功能一：地图SDK选择**（对应 `MapSDKPreference`）
| 选项 | 说明 | 行为 |
|------|------|------|
| 自动检测 | 根据GPS位置、SIM卡等信息自动选择最佳SDK | RegionDetector决定 |
| 高德地图 | 强制使用高德 | 忽略区域检测 |
| 谷歌地图 | 强制使用Google Maps | 忽略区域检测 |

**功能二：区域自动切换**（对应 `autoSwitchOnRegionChange`）
| 条件 | 行为 |
|------|------|
| 仅在"自动检测"模式下可用 | 其他模式下此选项灰显 |
| 开启 | 检测到跨境时弹出提示："检测到您已进入XX区域，建议切换到XX地图，是否切换？" |
| 关闭 | 不提示，保持当前SDK |

#### 4.2.6 SDK切换时的状态迁移（V5实现，V1不需要）

切换SDK时需要迁移的状态：
- 当前地图中心点和缩放级别
- 所有覆盖物（Marker、Polyline、Polygon）重新绘制
- 罗盘位置保持不变（基于WGS-84，与SDK无关）

不需要迁移的状态：
- 数据库数据（统一WGS-84，与SDK无关）
- 风水计算结果（纯数学，与SDK无关）

**关键原则：**
- 业务层只使用 `MapControllerProtocol`，不直接引用高德/Google SDK类型
- 坐标转换封装在各MapController实现内部
- 数据库统一存储WGS-84坐标
- V1只实现GaodeMapController，但接口设计已为双SDK做好预留
- 所有覆盖物操作通过Protocol进行，切换SDK时可无缝重建

### 4.3 坐标系统策略

```
GPS传感器 → WGS-84 (原始)
    ↓
存入数据库 → WGS-84 (统一存储)
    ↓
风水计算 → WGS-84 (直接用，Rhumb Line / Vincenty)
    ↓
地图显示 → 由MapController内部转换
           高德: WGS-84 → GCJ-02
           Google: WGS-84 → WGS-84 (无需转换)
```

### 4.4 相机优先级系统

解决的核心问题：多个来源同时触发相机移动时的竞态冲突。例如用户搜索跳转后，GPS定位回调不应把相机拉回当前位置。

```swift
enum CameraMoveSource: Int, Comparable {
    case gpsAutoLocate = 1    // 最低：自动GPS定位
    case mapInit = 2          // 地图初始化
    case userPointSelect = 3  // 用户选择点位
    case searchResult = 4     // 搜索结果跳转
    case userManual = 5       // 用户手动拖动（最高）

    static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}
```

**工作原理：**
1. 每次相机移动记录 `lastMoveSource` 和 `lastMoveTimestamp`
2. 低优先级操作（如GPS）发起移动前，检查当前优先级
3. 若当前优先级更高且未超时（3秒），则忽略低优先级操作
4. 超时后恢复为最低优先级，允许任何来源触发移动

```swift
// 在 MapViewModel 中实现
private var lastMoveSource: CameraMoveSource = .gpsAutoLocate
private var lastMoveTimestamp: Date = .distantPast
private let priorityTimeout: TimeInterval = 3.0

func requestCameraMove(to: WGS84Coordinate, zoom: Float, source: CameraMoveSource) {
    let elapsed = Date().timeIntervalSince(lastMoveTimestamp)
    if source < lastMoveSource && elapsed < priorityTimeout {
        return  // 被更高优先级阻止
    }
    lastMoveSource = source
    lastMoveTimestamp = Date()
    mapController.moveCamera(to: to, zoom: zoom, animated: true)
}
```

### 4.5 连线点击检测

**为什么需要自定义检测：** 高德/Google SDK的Polyline点击回调不稳定，线太细难以点击，且需要支持多条重叠线的优先级判断。

```swift
// 常量
let POLYLINE_CLICK_THRESHOLD: CGFloat = 60  // 像素，约为线宽的5倍
let POLYLINE_WIDTH: CGFloat = 12            // 线宽

// 点到线段距离算法（在屏幕坐标系中计算）
func pointToLineSegmentDistance(
    point: CGPoint,
    lineStart: CGPoint,
    lineEnd: CGPoint
) -> CGFloat {
    // 1. 计算投影点在线段上的参数 t (0~1)
    // 2. 若 t < 0，最近点为 lineStart；若 t > 1，最近点为 lineEnd
    // 3. 否则最近点为投影点
    // 4. 返回 point 到最近点的欧氏距离
}
```

**检测流程：**
1. 用户点击地图 → 获取屏幕坐标
2. 遍历所有可见Polyline，将其端点转为屏幕坐标
3. 计算点击位置到每条线段的距离
4. 距离 < `POLYLINE_CLICK_THRESHOLD` 的线段为候选
5. 多条候选时，选距离最近的那条

### 4.6 文字标签碰撞检测

终点标签（TextMarker）在地图上可能重叠，需要自动调整锚点位置避免遮挡。

```swift
// 8个锚点位置（按优先级排序）
let ANCHOR_POSITIONS: [(x: CGFloat, y: CGFloat)] = [
    (0.5, 1.0),   // 底部中心（默认，标签在标记点上方）
    (0.5, 0.0),   // 顶部中心
    (1.0, 0.5),   // 右侧中心
    (0.0, 0.5),   // 左侧中心
    (1.0, 1.0),   // 右下角
    (0.0, 1.0),   // 左下角
    (1.0, 0.0),   // 右上角
    (0.0, 0.0)    // 左上角
]
```

**算法：**
1. 对每个待放置的标签，依次尝试8个锚点位置
2. 计算该锚点下标签的屏幕矩形（Rect）
3. 检查是否与已放置标签的Rect相交
4. 找到第一个不冲突的位置即采用
5. 全部冲突则使用默认位置（底部中心）

### 4.7 重复终点检测

防止用户在同一位置附近重复添加终点。

```swift
let DUPLICATE_THRESHOLD_METERS: Double = 300  // 300米内视为重复

func isDuplicateDestination(
    newPoint: WGS84Coordinate,
    existingPoints: [WGS84Coordinate]
) -> Bool {
    return existingPoints.contains { existing in
        FengShuiEngine.calculateVincentyDistance(from: newPoint, to: existing)
            < DUPLICATE_THRESHOLD_METERS
    }
}
```

**触发时机：** 用户添加终点时，在写入数据库前检查。若检测到重复，弹出提示让用户确认。

### 4.8 竞态条件防护

异步数据加载时，用户可能快速切换案例/项目，导致旧的加载结果覆盖新的。使用 operationId 模式防护。

```swift
// 在 ViewModel 中实现
private var loadingOperationId: UUID?

func loadCaseData(caseId: Int) async {
    // 1. 生成唯一操作ID
    let operationId = UUID()
    self.loadingOperationId = operationId

    // 2. 禁用UI交互，防止加载期间操作
    self.isInteractionEnabled = false

    // 3. 执行异步数据加载
    let points = await repository.getPointsByCase(caseId)

    // 4. 检查operationId是否仍然有效（未被新操作覆盖）
    guard self.loadingOperationId == operationId else {
        return  // 已被更新的操作取代，丢弃结果
    }

    // 5. 更新UI状态
    self.points = points
    self.isInteractionEnabled = true
}
```

### 4.9 Toast/提示消息优先级队列

防止短时间内大量重复提示干扰用户，同时确保高优先级消息不被低优先级淹没。

```swift
enum ToastPriority: Int, Comparable {
    case low = 1        // 信息提示
    case normal = 2     // 操作反馈
    case high = 3       // 警告
    case urgent = 4     // 错误
    case critical = 5   // 严重错误

    static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}
```

**防重复机制：** 5秒时间窗口内，相同消息内容不重复显示。

```swift
class ToastManager: ObservableObject {
    private var recentMessages: [String: Date] = [:]
    private let duplicateWindow: TimeInterval = 5.0

    func show(_ message: String, priority: ToastPriority = .normal) {
        let now = Date()
        if let lastShown = recentMessages[message],
           now.timeIntervalSince(lastShown) < duplicateWindow {
            return  // 跳过重复消息
        }
        recentMessages[message] = now
        // 按优先级排序显示
    }
}
```

---

## 5. 项目目录结构

```
FengShuiLuopan/
├── FengShuiLuopan/
│   ├── App/                        # App入口
│   │   ├── FengShuiLuopanApp.swift # @main
│   │   └── ContentView.swift       # 根视图（TabView）
│   │
│   ├── Core/                       # 核心算法（纯Swift，无外部依赖）
│   │   ├── FengShuiEngine.swift    # 方位角(Rhumb)、距离(Vincenty)、24山/八卦/五行
│   │   ├── CoordinateConverter.swift # WGS-84 ↔ GCJ-02
│   │   └── Models/
│   │       ├── WGS84Coordinate.swift # 基础坐标类型（纯值类型，无SDK依赖）
│   │       ├── Mountain.swift      # 24山数据
│   │       ├── Trigram.swift       # 八卦数据
│   │       └── WuXing.swift        # 五行数据
│   │
│   ├── Data/                       # 数据层
│   │   ├── Database/
│   │   │   └── DatabaseManager.swift # SQLite.swift 初始化与迁移
│   │   ├── Models/
│   │   │   ├── GeoPoint.swift      # 地理坐标点
│   │   │   ├── FengShuiCase.swift  # 风水案例
│   │   │   ├── LifeCircle.swift    # 生活圈
│   │   │   └── AppSettings.swift   # 应用设置
│   │   └── Repositories/
│   │       ├── CaseRepository.swift
│   │       ├── PointRepository.swift
│   │       └── LifeCircleRepository.swift
│   │
│   ├── Services/                   # 服务层
│   │   ├── LocationService.swift   # Core Location 定位
│   │   └── Map/
│   │       ├── MapControllerProtocol.swift  # 地图抽象接口
│   │       └── GaodeMapController.swift     # 高德实现
│   │
│   ├── Features/                   # 功能模块（View + ViewModel）
│   │   ├── Map/
│   │   │   ├── MapView.swift       # 地图主页面
│   │   │   ├── MapViewModel.swift  # 地图状态管理
│   │   │   └── Components/
│   │   │       ├── NorthIndicator.swift    # 北方指示器（跟随地图旋转）
│   │   │       ├── CrosshairView.swift    # 十字准星
│   │   │       ├── SideButtonsView.swift  # 侧边按钮
│   │   │       └── LineInfoPanel.swift    # 连线信息面板
│   │   │
│   │   ├── CaseManagement/        # 案例管理（Phase 2）
│   │   │   ├── CaseListView.swift
│   │   │   └── CaseListViewModel.swift
│   │   │
│   │   ├── SectorSearch/          # 扇形搜索（Phase 3）
│   │   │   ├── SectorSearchView.swift
│   │   │   └── SectorSearchViewModel.swift
│   │   │
│   │   └── LifeCircle/           # 生活圈（Phase 4）
│   │       ├── LifeCircleView.swift
│   │       └── LifeCircleViewModel.swift
│   │
│   ├── Shared/                    # 共享组件
│   │   ├── Constants.swift        # 全局常量（数量限制等）
│   │   ├── Extensions/            # Swift扩展
│   │   └── Components/            # 可复用UI组件
│   │
│   ├── Resources/                 # 资源文件
│   │   └── Assets.xcassets
│   │
│   └── Info.plist
│
├── Podfile                        # CocoaPods依赖
├── ARCHITECTURE.md                # 本文档
├── CODING_CONVENTIONS.md          # 编码规范（待创建）
└── DEVELOPMENT_PLAN.md            # 开发计划（待创建）
```

---

## 6. 数据模型

### 6.1 GeoPoint（地理坐标点）

| 字段 | 类型 | 约束 | 说明 |
|------|------|------|------|
| id | INTEGER | PRIMARY KEY AUTOINCREMENT | 自增主键 |
| caseId | INTEGER | NOT NULL, FK → FengShuiCase(id) | 外键，关联案例 |
| name | TEXT | NOT NULL | 点位名称（如"大门"、"主卧"） |
| latitude | REAL | NOT NULL | WGS-84纬度 |
| longitude | REAL | NOT NULL | WGS-84经度 |
| role | INTEGER | NOT NULL, DEFAULT 0 | 0=原点(立极点)，1=终点(砂水点) |
| sortOrder | INTEGER | NOT NULL, DEFAULT 0 | 排序序号 |
| createdAt | TEXT | NOT NULL | ISO8601创建时间 |

**索引：**
- `idx_geopoint_case_role` ON (caseId, role) — 按案例+角色查询
- `idx_geopoint_case_sort` ON (caseId, sortOrder) — 按案例排序查询

### 6.2 FengShuiCase（风水案例）

| 字段 | 类型 | 约束 | 说明 |
|------|------|------|------|
| id | INTEGER | PRIMARY KEY AUTOINCREMENT | 自增主键 |
| title | TEXT | NOT NULL | 案例名称 |
| description | TEXT | — | 案例描述（可选） |
| type | INTEGER | NOT NULL, DEFAULT 0 | 0=普通案例，1=生活圈模式 |
| createdAt | TEXT | NOT NULL | ISO8601创建时间 |
| updatedAt | TEXT | NOT NULL | ISO8601更新时间 |

**索引：**
- `idx_case_type` ON (type) — 按类型筛选
- `idx_case_updated` ON (updatedAt DESC) — 按更新时间排序

### 6.3 LifeCircle（生活圈）

| 字段 | 类型 | 约束 | 说明 |
|------|------|------|------|
| id | INTEGER | PRIMARY KEY AUTOINCREMENT | 自增主键 |
| homeLat | REAL | — | 家的纬度 |
| homeLng | REAL | — | 家的经度 |
| workLat | REAL | — | 公司纬度 |
| workLng | REAL | — | 公司经度 |
| entertainLat | REAL | — | 娱乐纬度 |
| entertainLng | REAL | — | 娱乐经度 |
| isComplete | INTEGER | NOT NULL, DEFAULT 0 | 是否三点齐全 |

### 6.4 AppSettings（应用设置）

| 字段 | 类型 | 约束 | 说明 |
|------|------|------|------|
| id | INTEGER | PRIMARY KEY, DEFAULT 1 | 固定为1（单例） |
| compassMode | INTEGER | NOT NULL, DEFAULT 0 | 北方指示器模式：0=跟随地图旋转，1=始终指向正北 |
| mapLayerType | INTEGER | NOT NULL, DEFAULT 0 | 0=矢量图，1=卫星图 |
| mapSDKPreference | INTEGER | NOT NULL, DEFAULT 0 | 0=自动检测，1=高德，2=谷歌（V5+生效） |
| autoSwitchOnRegionChange | INTEGER | NOT NULL, DEFAULT 1 | 跨境自动切换提示：0=关闭，1=开启（仅自动检测模式下有效） |

### 6.5 数据库设计规范

**外键约束：**
- GeoPoint.caseId → FengShuiCase.id，ON DELETE CASCADE（删除案例时级联删除关联点位）
- SQLite.swift 初始化时启用外键：`db.execute("PRAGMA foreign_keys = ON")`

**迁移策略：**
- 使用版本号管理迁移：`PRAGMA user_version`
- 每次Schema变更对应一个版本号和迁移函数
- 迁移函数在 `DatabaseManager.migrate()` 中按版本号顺序执行
- 只允许向前迁移，不支持回滚

```swift
// 迁移示例结构
struct DatabaseManager {
    static let currentVersion = 1

    static func migrate(db: Connection) throws {
        let version = db.userVersion  // PRAGMA user_version
        if version < 1 {
            // V1: 初始表结构
            try createInitialTables(db)
        }
        // if version < 2 { ... }  // 未来迁移
        db.userVersion = currentVersion
    }
}
```

**数据完整性：**
- 所有时间字段使用ISO8601格式字符串（`yyyy-MM-dd'T'HH:mm:ss.SSSZ`）
- 坐标字段使用REAL类型，精度足够（IEEE 754双精度，约15位有效数字）
- 布尔值用INTEGER存储（0=false，1=true）

---

## 7. 数量限制常量

| 常量名 | 值 | 说明 |
|--------|-----|------|
| MAX_ORIGINS_PER_CASE | 2 | 每案例最多2个原点 |
| MAX_DESTINATIONS_PER_CASE | 5 | 每案例最多5个终点 |
| MAX_CASES_TRIAL | 2 | 试用版最多2个案例 |
| MAX_VISIBLE_POLYLINES | 50 | 地图最大可见连线数 |
| MAX_VISIBLE_TEXT_MARKERS | 50 | 地图最大可见文字标记 |
| MAX_POI_COUNT | 50 | 扇形搜索最大POI数 |
| MAX_LATITUDE | 85.05 | Web Mercator极地限制 |
| DUPLICATE_POINT_THRESHOLD | 300.0 | 重复终点检测阈值（米） |
| POLYLINE_CLICK_THRESHOLD | 60.0 | 连线点击热区（像素，约线宽5倍） |
| POLYLINE_WIDTH | 12.0 | 连线宽度（像素） |
| TOAST_DUPLICATE_WINDOW | 5.0 | Toast防重复时间窗口（秒） |
| CAMERA_PRIORITY_TIMEOUT | 3.0 | 相机优先级超时（秒） |

---

## 8. 连线颜色方案

终点连线按固定顺序使用以下颜色：

| 序号 | 颜色 | Hex | 用途 |
|------|------|-----|------|
| 1 | 红色 | #E53935 | 第1条终点连线 |
| 2 | 蓝色 | #1976D2 | 第2条终点连线 |
| 3 | 绿色 | #388E3C | 第3条终点连线 |
| 4 | 橙色 | #F57C00 | 第4条终点连线 |
| 5 | 紫色 | #7B1FA2 | 第5条终点连线 |

---

## 9. 版本规划

| 版本 | 功能范围 | Phase |
|------|---------|-------|
| V0.1.0 | 项目初始化 + 地图加载 + 真机验证 | Phase 0 |
| V0.5.0 | 地图 + 罗盘 + 单点连线 | Phase 1 |
| V1.0.0 | 多原点(≤2)多终点(≤5) + 案例管理 | Phase 2 |
| V2.0.0 | 扇形搜索 + POI + 十字准星选点 | Phase 3 |
| V3.0.0 | 生活圈 | Phase 4 |
| V4.0.0 | 新手指导 + 发布准备 | Phase 5-6 |
| V5.0.0 | Google Maps双SDK支持（远期） | 未规划 |

---

## 10. 生活圈模式

### 10.1 数据模型

```swift
struct LifeCircleData {
    let caseId: Int
    let homePoint: GeoPoint           // 家（原点1，罗盘最大）
    let workPoint: GeoPoint           // 公司（原点2，罗盘中等）
    let entertainmentPoint: GeoPoint  // 日常场所（原点3，罗盘最小）
}

struct LifeCircleConnection {
    let from: GeoPoint
    let to: GeoPoint
    let distance: Double      // 米
    let bearing: Double       // 0-360°
    let shanName: String      // 24山名称
}

enum LifeCirclePointType: String {
    case home           // 罗盘尺寸：最大
    case work           // 罗盘尺寸：中等
    case entertainment  // 罗盘尺寸：最小
}
```

### 10.2 激活流程

```
1. 用户点击「更多」→「生活圈模式」
2. 原点选择器变为多选模式（需选择3个原点）
3. 用户选择3个原点并点击「确定」
4. 显示角色分配对话框（RoleAssignmentDialog）
   ├─ 读取缓存：roleAssignmentCache[Set(id1,id2,id3)]
   ├─ 有缓存 → 显示历史分配
   └─ 无缓存 → 智能推荐（基于名称关键词）
5. 用户确认角色分配 → 保存到缓存（会话级别）
6. 激活生活圈：
   ├─ 隐藏主功能罗盘和连线
   ├─ 创建3个不同尺寸罗盘
   ├─ 绘制三角连线（三种颜色）
   ├─ 计算"指入"连线信息
   └─ 显示 LifeCircleBanner
```

### 10.3 "指入"逻辑

核心设计：每个罗盘上显示"指向它"的连线，而非"它指向"的连线。

| 罗盘 | 显示的连线 |
|------|-----------|
| 家 | 餐厅→家、公司→家 |
| 公司 | 家→公司、餐厅→公司 |
| 日常场所 | 公司→餐厅、家→餐厅 |

标签格式：`→来源名→ | 45.3° | 艮山 | 2.5km`

### 10.4 三角连线颜色编码

| 连线 | 颜色 | Hex |
|------|------|-----|
| 家 → 公司 | 绿色 | #00C853 |
| 公司 → 餐厅 | 蓝色 | #2196F3 |
| 餐厅 → 家 | 橙色 | #FF9800 |

### 10.5 智能角色推荐算法

```swift
let homeKeywords = Set(["家", "住宅", "小区", "公寓", "楼盘", "房", "宅", "居"])
let workKeywords = Set(["公司", "办公", "工作", "单位", "企业", "写字楼", "厂", "店"])
let entertainmentKeywords = Set(["餐厅", "商场", "健身", "娱乐", "咖啡", "超市", "饭店"])
```

两轮匹配：
1. 第一轮：明确匹配（某个类别得分显著高于其他）
2. 第二轮：为剩余原点分配剩余角色（按列表顺序）

### 10.6 角色分配缓存

```swift
// Key: 原点ID集合（无序），Value: 角色映射
var roleAssignmentCache: [Set<Int>: [Int: LifeCirclePointType]] = [:]
// 生命周期：会话级别（MapView销毁时清空，防止跨案例污染）
```

---

## 11. 试用限制与功能开关

### 11.1 功能开关（FeatureFlags）

```swift
struct FeatureFlags {
    static let enableCloudSync = false      // 云端同步（V5+）
    static let enableRegistration = false   // 注册码系统（V4+）
}
```

**设计原则：**
- 所有新功能默认关闭，确保生产稳定
- 支持灰度发布和快速回滚
- 开关在编译时确定（`static let`），不引入运行时复杂度

### 11.2 试用限制

| 限制项 | 试用版 | 注册版 |
|--------|--------|--------|
| 案例数量 | ≤2 | 无限制 |
| 每案例原点 | ≤2 | ≤2（设计限制，非试用限制） |
| 每案例终点 | ≤5 | ≤5（设计限制，非试用限制） |
| GPS原点 | 不计入限制 | 不计入限制 |

```swift
enum TrialLimitType {
    case caseCount
    case originCount
    case destinationCount
}

struct TrialLimitError: Error {
    let limitType: TrialLimitType
    let message: String
}
```

**检查时机：** 在 Repository 的 `createCase()` / `createPoint()` 中检查，超限时抛出 `TrialLimitError`，ViewModel 捕获后弹出提示。

### 11.3 GPS原点特殊处理

```swift
let GPS_ORIGIN_ID = "gps_location_origin"  // 固定标识

// 特性：
// - 系统自动创建，不可删除/重命名
// - 坐标随GPS定位实时更新
// - 不占用用户原点配额（试用限制不计算）
// - 每个案例可以有一个GPS原点
```

---

## 12. 性能优化与边界处理

### 12.1 地图覆盖物生命周期管理

**iOS适配（借鉴Android华为黑屏问题的思路）：**

iOS上虽然没有华为Mali GPU的OpenGL纹理丢失问题，但仍需管理地图覆盖物的生命周期：

```swift
// 在SwiftUI中通过 .onDisappear / .onAppear 管理
.onDisappear {
    // 释放大型Bitmap资源（如罗盘图片）
    compassImageCache = nil
}
.onAppear {
    // 按需重建
    if compassImageCache == nil {
        compassImageCache = renderCompassImage()
    }
}
```

**罗盘图片内存：** 罗盘Bitmap约3.8MB（1000x1000 ARGB），需要在页面不可见时释放。

### 12.2 覆盖物数量动态调整

根据设备内存情况动态调整最大覆盖物数量：

```swift
func getMaxOverlayCount() -> Int {
    let totalMemory = ProcessInfo.processInfo.physicalMemory
    let availableMemory = os_proc_available_memory()
    let usagePercent = 1.0 - (Double(availableMemory) / Double(totalMemory))

    switch usagePercent {
    case 0.8...: return 25   // 内存紧张
    case 0.6...: return 35   // 内存中等
    default:     return 50   // 正常
    }
}
```

### 12.3 高德SDK隐私合规配置（iOS）

```swift
// AppDelegate 或 App init 中，必须在SDK使用前调用
AMapServices.shared().enableHTTPS = true
AMapServices.shared().apiKey = "16d5c89d0a14758cae55c218e2bd3322"
// iOS高德SDK隐私合规：
// MAMapView.updatePrivacyShow(.didShow, privacyAgree: .didAgree)
```

---

## 13. 数据层扩展策略

### 13.1 当前架构（V1-V4）

```
SQLite.swift（唯一存储，本地）
```

V1-V4阶段只使用SQLite本地存储，简单可靠。

### 13.2 未来扩展预留（V5+，借鉴双写模式）

```
┌─────────────────────────────┐
│  层1: SQLite（主存储，必需）   │  ← 同步写入，立即生效
├─────────────────────────────┤
│  层2: 云端同步（可选）         │  ← 异步，FeatureFlag控制
│  - 由 FeatureFlags 控制开关   │
│  - 失败静默，不影响主流程      │
└─────────────────────────────┘
```

**设计原则：**
- SQLite为唯一真相源，云端同步是可选附加层
- 云端同步失败不影响本地功能
- 通过 `FeatureFlags.enableCloudSync` 控制
- V1-V4不实现云端同步，但Repository接口预留扩展点

---

## 14. 开发环境与流程

### 14.1 环境

| 项目 | 说明 |
|------|------|
| 日常开发 | Windows + VS Code，编写所有Swift代码 |
| 真机测试 | 按需租用云Mac（每次1-2小时） |
| 代码同步 | GitHub私有仓库（唯一真相源） |
| 测试机 | iPhone X（二手） |
| Apple ID | 已有（免费真机调试） |

### 14.2 开发原则

1. **决策优先级**：设计正确性 > 代码简洁性 > 开发速度
2. **高风险优先**：地图、手势、传感器相关功能尽早真机验证
3. **Windows开发原则**：所有Swift代码在Windows编写，集中验证
4. **租用云Mac原则**：每次租用前确保代码已推送，有明确验证列表
5. **唯一真相原则**：技术决策以本文档为准，代码实现必须与本文档一致

### 14.3 AI编程规则

- 本项目是iOS原生Swift项目，不是Flutter项目
- 不要引用或修改任何 `.dart` 文件
- 所有代码必须符合本文档的技术选型（特别是Rhumb Line方位角）
- 新增技术依赖前必须先更新本文档

---

## 15. 测试策略

### 15.1 测试分层

| 层级 | 框架 | 运行环境 | 覆盖范围 |
|------|------|---------|---------|
| 单元测试 | XCTest | Mac（无需真机） | Core层算法、ViewModel逻辑 |
| 集成测试 | XCTest | Mac/真机 | 数据库操作、Service层 |
| UI冒烟测试 | 手动 | 真机（iPhone X） | 地图交互、传感器、手势 |

### 15.2 Core层单元测试（重点）

Core层是纯Swift代码，无SDK依赖，可在Mac上直接运行，是测试投入产出比最高的部分。

**必测项：**
- FengShuiEngine：Rhumb Line方位角、Vincenty距离、24山映射、扇形终点计算
- CoordinateConverter：WGS-84 ↔ GCJ-02 双向转换精度
- 边界情况：跨180°经线、极地附近、零距离、同点计算

**验证基准（来自大佬参考文档）：**
```
北京→上海：方位角 ≈ 136.°  距离 ≈ 1,067 km
同点计算：方位角 = 0°  距离 = 0 m
正北方向：(39.9, 116.4) → (40.9, 116.4) 方位角 = 0°
正东方向：(39.9, 116.4) → (39.9, 117.4) 方位角 = 90°
```

### 15.3 ViewModel测试

通过 Protocol 注入 Mock 的 MapController，测试业务逻辑而不依赖真实地图SDK。

```swift
// 测试用 Mock
class MockMapController: MapControllerProtocol {
    var lastMovedTo: WGS84Coordinate?
    var markers: [String: WGS84Coordinate] = [:]
    // ... 记录调用，不做真实渲染
}
```

### 15.4 真机验证清单

每次租用云Mac时，按以下清单逐项验证：

- [ ] 编译通过（Release + Debug）
- [ ] 地图加载并显示
- [ ] GPS定位正常
- [ ] 标记点添加/删除
- [ ] 北方指示器跟随地图旋转
- [ ] 当前Phase的核心功能

---

## 16. 参考文档中的关键设计模式（待实现时细化）

以下设计模式来自大佬参考文档，在对应Phase实现时再细化：

- **相机优先级系统** — 已细化（见4.4节）
- **连线点击检测** — 已细化（见4.5节）
- **文字标签碰撞检测** — 已细化（见4.6节）
- **重复终点检测** — 已细化（见4.7节）
- **竞态条件防护** — 已细化（见4.8节）
- **Toast优先级队列** — 已细化（见4.9节）
- **扇形POI搜索过滤算法** — 已细化（见3.6节）
- **生活圈模式** — 已细化（见第10节）
- **GPS原点特殊处理** — 已细化（见11.3节）
- **试用限制** — 已细化（见11.2节）
- **功能开关** — 已细化（见11.1节）
- **数据层扩展策略** — 已细化（见第13节）
- **覆盖物生命周期管理** — 已细化（见12.1节）
- **搜索→十字准星→确认完整流程**（待Phase 3实现时细化到PHASE_V2_SPEC.md）

---

## 17. 待讨论/待定事项

- [x] Google Maps双SDK预留架构设计 — 已完成（见4.2节，接口已定义，V5实现）
- [x] 地图SDK自动切换方案 — 已完成（见4.2.5节，三种模式+跨境提示）
- [ ] RegionDetector具体实现细节（GPS围栏坐标、SIM卡MCC判断逻辑，推迟到V5）
- [ ] App Store发布相关（取决于是否购买付费开发者账号¥688/年）
- [ ] Google Maps API Key申请与配置（推迟到V5）
