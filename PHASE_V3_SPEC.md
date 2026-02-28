# Phase 3 (V2.0.0) - 扇形搜索与POI功能

## 版本目标

实现扇形区域搜索、POI搜索与过滤、十字准心选点模式。

## 新增功能

### 1. 扇形搜索

#### 1.1 进入扇形搜索
**触发方式：** 在主界面"地图"的右侧按键区，点击圆圈按钮

**行为：** 弹出"选择扇形区域"页面

#### 1.2 扇形起点确定
- **有原点时：** 以原点作为扇形的起点，绘制扇形区域
- **无原点时：** 以地图屏幕中心作为扇形的起点，绘制扇形区域

#### 1.3 扇形区域绘制设置

**页面布局：**
```
┌─────────────────────────────────┐
│  选择扇形区域                    │
├─────────────────────────────────┤
│  方位选择：                      │
│  ○ 24山模式 (默认)              │
│  ○ 八方位模式                   │
│                                 │
│  [24山选择器/八方位选择器]       │
├─────────────────────────────────┤
│  POI关键词（可选）：             │
│  [搜索框]                       │
│  提示：未输入关键词时只绘制扇形区域│
│                                 │
│  快捷关键词：                    │
│  [住宅] [医院] [大厦]           │
├─────────────────────────────────┤
│  搜索距离：                      │
│  [20.0] [千米 ▼]               │
│                                 │
│  快捷距离：                      │
│  [20km] [50km] [200km]         │
│  [1000km] [3000km] [5000km]    │
├─────────────────────────────────┤
│  [取消] [绘制区域/绘制并搜索]    │
└─────────────────────────────────┘
```

##### 1.3.1 方位选择
**24山模式（默认）：**
- 以15度精准方位（对应传统24山方位）作为绘制的扇形的朝向
- 扇形角度：15度
- 24山选择器显示所有24山选项

**八方位模式：**
- 以45度宽扇形（对应正北、东北、正东等8个方位）作为绘制的扇形的朝向
- 扇形角度：45度
- 八方位选择器显示8个方位选项

**八方位到24山映射：** 见ARCHITECTURE.md 3.6节

##### 1.3.2 POI关键词设置
**搜索框：**
- 默认留空
- 提示："未输入关键词时只绘制扇形区域"
- 可手动输入搜索关键词
- 可一键填入预设关键词："住宅"、"医院"、"大厦"

**按键变化：**
- 留空状态：页面右下角为"取消/绘制区域"按键
- 填入关键词后：页面右下角为"取消/绘制并搜索"按键

##### 1.3.3 搜索距离设置
**数字框：**
- 默认值：20.0
- 点击数字框可启用用户键盘数字按键进行更改
- 单位默认：千米
- 可切换单位：米/千米

**快捷距离：**
- 可一键填入预设距离："20km"、"50km"、"200km"、"1000km"、"3000km"、"5000km"

**特殊情况：**
- 当用户输入的距离 < 100米时：
  - 提示"最小距离100米"
  - 禁止"绘制并搜索"或"绘制区域"按键
- 当用户输入的距离 > 5000千米时：
  - 提示"最大距离5000千米（Mercator投影限制）"
  - 禁止"绘制并搜索"或"绘制区域"按键

#### 1.4 扇形区域绘制与POI搜索

**触发方式：** 点击"选择扇形区域"右下角的"绘制并搜索"或"绘制区域"按键

##### 1.4.1 扇形区域绘制
**绘制逻辑：**
1. 根据距离信息，比对地图上比例尺信息，设置合适长度的扇形两翼长度
2. 结合起点、方位、扇形两翼长度信息，在地图上以虚线绘制扇形两翼
3. 当用户拖动、缩放地图时，收集新的起点、比例尺信息，及时绘制新的扇形两翼

**扇形绘制算法：** 见ARCHITECTURE.md 3.4节

##### 1.4.2 POI搜索（若关键词非空）
**搜索限制：**
- 当搜索距离超过250km时，提示"POI搜索限制在250km内"

**搜索流程：**
1. 提示正在搜索【x】...（x为用户所填写的POI关键词）
2. 接入地图搜索模块，搜索用户输入的POI关键词
3. 返回数量、位置信息
4. 使用扇形过滤算法过滤POI（见ARCHITECTURE.md 3.6节）
5. 将距离优先的50个POI位置标在地图上

**搜索完成提示：**
- 有结果：提示"在y范围内找到z个a"
  - y为搜索距离
  - z为地图返回的搜索结果数量
  - a为用户所填写的POI关键词
- 无结果：提示"该区域内未找到【x】"

#### 1.5 已绘制扇形的再次编辑
**触发方式：** 已绘制扇形区域的情况下，再次点击圆圈按钮

**按键变化：**
- 页面右下角"取消/绘制区域"改为"取消/清除区域/绘制区域"
- 页面右下角"取消/绘制并搜索"改为"取消/清除区域/绘制并搜索"

#### 1.6 扇形设置保留
**保留规则：**
- 若用户点击"清除区域/绘制区域"或"清除区域/绘制并搜索"：
  - 保留用户上一次的扇形区域绘制设置
  - 在下次进入"选择扇形区域"页面时填入上一次的扇形区域绘制设置
- 若用户点击"取消"：
  - 不保留设置

### 2. 搜索功能与十字准心模式

#### 2.1 搜索页面
**触发方式：** 菜单第三个按键为"搜索"，点击后主页面切换为POI搜索页面

**页面布局：**
```
┌─────────────────────────────────┐
│  [搜索框]                       │
├─────────────────────────────────┤
│  搜索结果：                      │
│                                 │
│  📍 结果1                       │
│     地址信息                     │
│                                 │
│  📍 结果2                       │
│     地址信息                     │
│                                 │
│  ...                            │
└─────────────────────────────────┘
```

**功能：**
- 页面上方为搜索框
- 实时根据输入内容及时接入地图模块进行搜索
- 返回所有名字与位置信息
- 陈列在POI搜索页面内
- 点击搜索内容，切换到地图主界面并进入十字准心模式

#### 2.2 十字准心模式
**触发方式：** 在搜索页面点击搜索结果

**行为：**
1. 地图主页面定位到用户所点击的搜索内容地址
2. 屏幕中心为十字准心
3. 允许用户拖动地图微调位置
4. 提示："调整位置：拖拽地图微调十字准心位置，调整好后点击下面按钮保存"

**页面布局：**
```
┌─────────────────────────────────┐
│  [地图区域]                      │
│                                 │
│         ✛ (十字准心)            │
│                                 │
│                                 │
├─────────────────────────────────┤
│  调整位置：拖拽地图微调十字准心位置│
│  调整好后点击下面按钮保存         │
├─────────────────────────────────┤
│  保存为：                        │
│  [选择案例 ▼]                   │
│  ○ 原点  ○ 终点                │
│                                 │
│  [取消] [保存]                  │
└─────────────────────────────────┘
```

#### 2.3 保存十字准心位置
**功能：**
- 接入堪舆管理与点位管理模块
- 可将十字准心位置保存为已选的堪舆案例
- 或创建新的堪舆案例用于保存十字准心位置
- 可选保存为所选堪舆案例中原点或终点
- 或取消保存

## UI布局更新

### 主界面布局
```
┌─────────────────────────────────┐
│  [地图区域]                      │
│                                 │
│         ┼ (十字指示)             │  右侧按键区：
│                                 │  - [+] 加号
│      🧭 (罗盘)                  │  - [+/-] 缩放
│                                 │  - [🗺] 地图类型
│                                 │  - [📍] 定位按钮
│                                 │  - [🔒/🔓] 罗盘模式
│                                 │  - [📌] 原点按钮
│                                 │  - [📍] 终点按钮
│                                 │  - [📋] 列表按钮
│                                 │  - [⭕] 扇形搜索 (新增)
├─────────────────────────────────┤
│  [地图] [堪舆管理] [搜索]       │  ← 底部菜单栏 (新增搜索)
└─────────────────────────────────┘
```

## 数据模型

### SectorSearchConfig
```swift
struct SectorSearchConfig {
    var mode: SectorMode           // 24山模式 / 八方位模式
    var direction: Direction       // 选择的方向
    var poiKeyword: String?        // POI关键词（可选）
    var distance: Double           // 搜索距离（米）
    var distanceUnit: DistanceUnit // 米 / 千米
}

enum SectorMode {
    case shan24    // 24山模式（15度）
    case bagua8    // 八方位模式（45度）
}

enum Direction {
    // 24山
    case zi, gui, chou, gen, yin, jia, mao, yi, chen,
         xun, si, bing, wu, ding, wei, kun, shen, geng,
         you, xin, xu, qian, hai, ren

    // 八方位
    case north, northeast, east, southeast,
         south, southwest, west, northwest
}

enum DistanceUnit: String {
    case meter = "米"
    case kilometer = "千米"
}
```

### POIResult
```swift
struct POIResult {
    let id: String
    let name: String
    let address: String
    let coordinate: WGS84Coordinate
    let distance: Double        // 距离起点的距离（米）
    let bearing: Double         // 方位角（0-360°）
    let category: String?       // POI类别
}
```

## 技术实现要点

### 1. 扇形区域绘制

#### 1.1 扇形终点计算
见ARCHITECTURE.md 3.4节

```swift
func calculateSectorEndpoints(
    origin: WGS84Coordinate,
    startAngle: Double,
    endAngle: Double,
    radius: Double
) -> (leftEnd: WGS84Coordinate, rightEnd: WGS84Coordinate) {
    // 使用Rhumb Line计算扇形两翼终点
    let leftEnd = FengShuiEngine.calculateRhumbDestination(
        from: origin,
        bearing: startAngle,
        distance: radius
    )
    let rightEnd = FengShuiEngine.calculateRhumbDestination(
        from: origin,
        bearing: endAngle,
        distance: radius
    )
    return (leftEnd, rightEnd)
}
```

#### 1.2 扇形绘制
```swift
func drawSector(origin: WGS84Coordinate,
                startAngle: Double,
                endAngle: Double,
                radius: Double) {
    // 计算扇形两翼终点
    let (leftEnd, rightEnd) = calculateSectorEndpoints(
        origin: origin,
        startAngle: startAngle,
        endAngle: endAngle,
        radius: radius
    )

    // 绘制左翼虚线
    let leftLine = MAPolyline(coordinates: [origin, leftEnd], count: 2)
    leftLine.strokeColor = UIColor.blue.withAlphaComponent(0.5)
    leftLine.lineWidth = 2
    leftLine.lineDashType = .dashed
    mapView.add(leftLine)

    // 绘制右翼虚线
    let rightLine = MAPolyline(coordinates: [origin, rightEnd], count: 2)
    rightLine.strokeColor = UIColor.blue.withAlphaComponent(0.5)
    rightLine.lineWidth = 2
    rightLine.lineDashType = .dashed
    mapView.add(rightLine)
}
```

### 2. POI搜索与过滤

#### 2.1 高德POI搜索
```swift
func searchPOI(keyword: String,
               center: WGS84Coordinate,
               radius: Double) async -> [POIResult] {
    // 转换为GCJ-02坐标
    let gcjCoord = CoordinateConverter.wgs84ToGcj02(center)

    // 调用高德POI搜索
    let request = AMapPOIAroundSearchRequest()
    request.keywords = keyword
    request.location = AMapGeoPoint.location(
        withLatitude: CGFloat(gcjCoord.latitude),
        longitude: CGFloat(gcjCoord.longitude)
    )
    request.radius = Int(radius)
    request.requireExtension = true

    let response = await search.aMapPOIAroundSearch(request)

    // 转换结果为WGS-84坐标
    return response.pois.map { poi in
        let wgsCoord = CoordinateConverter.gcj02ToWgs84(
            GCJ02Coordinate(
                latitude: poi.location.latitude,
                longitude: poi.location.longitude
            )
        )
        return POIResult(
            id: poi.uid,
            name: poi.name,
            address: poi.address,
            coordinate: wgsCoord,
            distance: poi.distance,
            bearing: 0,  // 待计算
            category: poi.type
        )
    }
}
```

#### 2.2 扇形POI过滤
见ARCHITECTURE.md 3.6节

```swift
func filterPOIsInSector(
    origin: WGS84Coordinate,
    pois: [POIResult],
    startAngle: Double,
    endAngle: Double,
    maxDistance: Double
) -> [POIResult] {
    return pois.filter { poi in
        // 1. 计算原点到POI的Rhumb Line方位角
        let bearing = FengShuiEngine.calculateRhumbBearing(
            from: origin,
            to: poi.coordinate
        )

        // 2. 判断方位角是否在扇形范围内
        let inAngle = isAngleInRange(bearing, start: startAngle, end: endAngle)

        // 3. 判断距离是否在范围内
        let distance = FengShuiEngine.calculateVincentyDistance(
            from: origin,
            to: poi.coordinate
        )

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

### 3. 十字准心模式

#### 3.1 进入十字准心模式
```swift
func enterCrosshairMode(at coordinate: WGS84Coordinate) {
    // 切换到地图页面
    tabBarController.selectedIndex = 0

    // 移动相机到目标位置
    mapController.moveCamera(
        to: coordinate,
        zoom: 16,
        animated: true,
        source: .search
    )

    // 显示十字准心UI
    showCrosshairUI()

    // 显示保存面板
    showSavePanel()
}
```

#### 3.2 保存十字准心位置
```swift
func saveCrosshairPosition(
    caseId: Int,
    pointType: PointType,
    name: String
) async throws {
    // 获取屏幕中心坐标
    let centerCoordinate = mapView.centerCoordinate

    // 创建点位
    try await repository.createPoint(
        caseId: caseId,
        name: name,
        coordinate: centerCoordinate,
        pointType: pointType
    )

    // 退出十字准心模式
    exitCrosshairMode()

    // 显示成功提示
    showToast("保存成功", priority: .normal)
}
```

## 交互流程

### 1. 扇形搜索流程
```
用户点击圆圈按钮
  ↓
弹出"选择扇形区域"页面
  ↓
选择方位模式（24山/八方位）
  ↓
选择具体方向
  ↓
输入POI关键词（可选）
  ↓
设置搜索距离
  ↓
点击"绘制区域"或"绘制并搜索"
  ↓
绘制扇形两翼虚线
  ↓
（若有POI关键词）执行POI搜索
  ↓
过滤扇形内的POI
  ↓
在地图上标注POI位置
```

### 2. 十字准心选点流程
```
用户在搜索页面输入关键词
  ↓
显示搜索结果列表
  ↓
用户点击某个搜索结果
  ↓
切换到地图页面
  ↓
进入十字准心模式
  ↓
地图中心定位到搜索结果位置
  ↓
用户拖动地图微调位置
  ↓
选择保存到的案例
  ↓
选择保存为原点/终点
  ↓
点击保存
  ↓
创建点位
  ↓
退出十字准心模式
```

## 测试验证清单

- [ ] 扇形搜索按钮正常工作
- [ ] "选择扇形区域"页面正常显示
- [ ] 24山模式扇形绘制正确（15度）
- [ ] 八方位模式扇形绘制正确（45度）
- [ ] 扇形起点自动选择正确（有原点用原点，无原点用屏幕中心）
- [ ] POI关键词输入正常
- [ ] 快捷关键词按钮正常工作
- [ ] 搜索距离设置正常
- [ ] 快捷距离按钮正常工作
- [ ] 距离限制检查正常（100米-5000千米）
- [ ] 扇形两翼虚线绘制正确
- [ ] 拖动/缩放地图时扇形实时更新
- [ ] POI搜索正常工作
- [ ] 扇形POI过滤算法正确
- [ ] POI标注在地图上正确显示
- [ ] POI搜索限制（250km）正常工作
- [ ] 搜索提示信息正确显示
- [ ] 已绘制扇形的再次编辑正常
- [ ] 扇形设置保留功能正常
- [ ] 搜索页面正常显示
- [ ] 实时搜索功能正常
- [ ] 点击搜索结果进入十字准心模式
- [ ] 十字准心模式UI正常显示
- [ ] 拖动地图微调位置正常
- [ ] 保存十字准心位置正常
- [ ] 跨0度角度范围判断正确

## 已知限制

- 不支持生活圈模式
- 不支持新手指导
- 不支持使用说明

## 下一阶段预告

Phase 4 (V3.0.0) 将添加：
- 生活圈模式
- 三点三角连线
- 角色分配对话框
- "指入"逻辑
