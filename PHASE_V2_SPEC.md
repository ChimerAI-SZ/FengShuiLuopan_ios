# Phase 2 (V1.0.0) - 多原点多终点与案例管理

## 版本目标

实现完整的多原点多终点功能、案例管理系统、原点/终点选择器。

## 新增功能

### 1. 多原点多终点

#### 1.1 数量限制
- 每案例最多2个原点（`MAX_ORIGINS_PER_CASE = 2`）
- 每案例最多5个终点（`MAX_DESTINATIONS_PER_CASE = 5`）
- 试用版最多2个案例（`MAX_CASES_TRIAL = 2`）
- GPS原点不计入原点配额

#### 1.2 添加点位
**触发方式：** 点击加号或点击屏幕中心十字指示

**流程：**
1. 屏幕中间弹出"加点提示"对话框
2. 输入点的名称（必填）
3. 选择点所属的堪舆案例（下拉选择）
4. 选择点属于终点还是原点（单选）
5. 点击"保存"完成加点，点击"取消"则无事发生

**加点后效果：**
- 只显示当前原点和该原点对应的所有终点之间的连线
- 不显示非当前案例的所有终点和连线
- 点击连线显示两点间信息（与Phase 0相同）

#### 1.3 重复终点检测
- 检测阈值：300米（`DUPLICATE_POINT_THRESHOLD = 300.0`）
- 触发时机：用户添加终点时，在写入数据库前检查
- 若检测到重复，弹出提示让用户确认
- 算法见ARCHITECTURE.md 4.7节

### 2. 原点/终点选择器

#### 2.1 原点选择器
**触发方式：** 点击地图界面右侧按键区"原点按钮"

**功能：**
- 显示当前案例的所有原点列表
- 只能选择一个原点（单选）
- 选择后：
  - 罗盘切换为锁定模式
  - 屏幕中心移动到当前原点位置
  - 自动显示当前原点对应的案例的所有终点
  - 显示当前原点与这些终点之间的连线
  - 不显示非当前案例的所有终点和连线

**无原点时：**
- 提示"暂无原点，请在堪舆管理中添加。"

#### 2.2 终点选择器
**触发方式：** 点击地图界面右侧按键区"终点按钮"

**功能：**
- 显示当前案例的所有终点列表
- 可多选，但必须为同一堪舆案例下的终点
- 有"全选"按钮：
  - 点击会选择选中案例的所有终点
  - 若未选择案例，则提示"请先选择案例"
- 有"清空"按钮：
  - 点击会取消选中当前案例的所有终点
  - 若未选择案例，则提示"请先选择案例"
- 选择后点击"确定"：
  - 提示选择当前终点案例下的哪一个原点
  - 选好后点"确定"
  - 屏幕中仅会显示要显示的终点和选定原点之间的连线和信息

**无终点时：**
- 提示"暂无终点，请在堪舆管理中添加"

#### 2.3 当前案例自动切换
- 凡是选定或添加或选择显示原点/终点，则默认该原点/终点所在案例为当前案例

#### 2.4 列表按钮
**触发方式：** 点击主界面右侧按键区"列表按钮"

**功能：**
- 查看当前案例的所有点位
- 显示点位名称、类型（原点/终点）、坐标

### 3. 案例管理

#### 3.1 底部菜单栏
- 菜单栏按键包括："地图"、"堪舆管理"
- 默认状态下是"地图"页面
- 可以选择"堪舆管理"切换到案例管理页面

#### 3.2 堪舆管理页面

**页面布局：**
```
┌─────────────────────────────────┐
│  [搜索栏]                  [+]  │  ← 右上角小加号
├─────────────────────────────────┤
│  案例1                    [>]   │  ← 左侧箭头展开
│    案例名称                     │
│    案例描述                     │
├─────────────────────────────────┤
│  案例2                    [>]   │
│    案例名称                     │
│    案例描述                     │
└─────────────────────────────────┘
```

**功能：**
1. **搜索栏：** 可以搜索堪舆案例（按案例名称）
2. **右上角小加号：** 点击后弹出"新建堪舆案例"对话框
   - 必填："案例名称"
   - 可选："案例描述"
   - 点击"创建"后建立案例
   - 点击"取消"则无事发生
3. **案例列表：** 展示案例名称和案例描述
4. **左侧箭头：** 点击可展开案例
   - 展开后显示该案例所包含的原点和终点
   - 可删除这些点
   - 可修改点位名称
   - 可点击右侧小加号进行加点
     - 加入方式包括：输入经纬度、地图选点
     - 地图选点会自动跳转地图界面的选点模式
5. **右边编辑按钮：** 可修改案例名称

### 4. 多终点连线颜色

#### 4.1 颜色方案
终点连线按固定顺序使用以下颜色（见ARCHITECTURE.md第8节）：

| 序号 | 颜色 | Hex |
|------|------|-----|
| 1 | 蓝色 | #2196F3 |
| 2 | 绿色 | #4CAF50 |
| 3 | 橙色 | #FF9800 |
| 4 | 紫色 | #9C27B0 |
| 5 | 红色 | #F44336 |

#### 4.2 颜色分配规则
- 第1个终点使用蓝色
- 第2个终点使用绿色
- 第3个终点使用橙色
- 第4个终点使用紫色
- 第5个终点使用红色
- 终点的标记点也使用相同颜色

### 5. GPS原点完整实现

#### 5.1 GPS原点特性
- 系统自动创建，不可删除/重命名
- 坐标随GPS定位实时更新
- 不占用用户原点配额（试用限制不计算）
- 每个案例可以有一个GPS原点
- 固定标识：`GPS_ORIGIN_ID = "gps_location_origin"`
- 固定名称："当前位置"

#### 5.2 GPS原点更新机制
```swift
// 监听GPS位置更新
func locationManager(_ manager: CLLocationManager,
                     didUpdateLocations locations: [CLLocation]) {
    guard let location = locations.last else { return }

    // 更新GPS原点坐标
    if let gpsOrigin = currentCase.origins.first(where: { $0.id == GPS_ORIGIN_ID }) {
        gpsOrigin.coordinate = WGS84Coordinate(
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude
        )

        // 更新地图上的罗盘位置
        updateCompassPosition(for: gpsOrigin)

        // 重新计算所有连线
        recalculateConnections()
    }
}
```

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
│                                 │  - [📌] 原点按钮 (新增)
│                                 │  - [📍] 终点按钮 (新增)
│                                 │  - [📋] 列表按钮 (新增)
├─────────────────────────────────┤
│  [地图] [堪舆管理]              │  ← 底部菜单栏 (新增)
└─────────────────────────────────┘
```

## 数据模型更新

### FengShuiCase
```swift
struct FengShuiCase {
    let id: Int
    var name: String
    var description: String?
    var origins: [GeoPoint]        // 最多2个（不含GPS原点）
    var destinations: [GeoPoint]   // 最多5个
    let createdAt: Date
    var updatedAt: Date
}
```

### GeoPoint (完整版)
```swift
struct GeoPoint {
    let id: Int
    let caseId: Int
    var name: String
    var coordinate: WGS84Coordinate
    let pointType: PointType
    let isGPSOrigin: Bool          // 是否为GPS原点
    let createdAt: Date
    var updatedAt: Date
}
```

## 技术实现要点

### 1. 试用限制检查
```swift
func createCase(name: String, description: String?) throws -> FengShuiCase {
    let existingCases = repository.getAllCases()

    // 检查试用限制
    if !isRegistered && existingCases.count >= MAX_CASES_TRIAL {
        throw TrialLimitError(
            limitType: .caseCount,
            message: "试用版最多创建\(MAX_CASES_TRIAL)个案例"
        )
    }

    // 创建案例
    return repository.createCase(name: name, description: description)
}
```

### 2. 原点/终点数量检查
```swift
func createPoint(caseId: Int, name: String,
                 coordinate: WGS84Coordinate,
                 pointType: PointType) throws -> GeoPoint {
    let existingPoints = repository.getPointsByCase(caseId)

    // 检查原点数量
    if pointType == .origin {
        let originCount = existingPoints.filter {
            $0.pointType == .origin && !$0.isGPSOrigin
        }.count

        if originCount >= MAX_ORIGINS_PER_CASE {
            throw TrialLimitError(
                limitType: .originCount,
                message: "每案例最多\(MAX_ORIGINS_PER_CASE)个原点"
            )
        }
    }

    // 检查终点数量
    if pointType == .destination {
        let destCount = existingPoints.filter {
            $0.pointType == .destination
        }.count

        if destCount >= MAX_DESTINATIONS_PER_CASE {
            throw TrialLimitError(
                limitType: .destinationCount,
                message: "每案例最多\(MAX_DESTINATIONS_PER_CASE)个终点"
            )
        }
    }

    // 重复终点检测
    if pointType == .destination {
        if isDuplicateDestination(coordinate, existingPoints) {
            // 弹出确认对话框
            let confirmed = await showConfirmDialog(
                "检测到300米内已有终点，是否继续添加？"
            )
            if !confirmed {
                throw CancellationError()
            }
        }
    }

    // 创建点位
    return repository.createPoint(
        caseId: caseId,
        name: name,
        coordinate: coordinate,
        pointType: pointType
    )
}
```

### 3. 连线颜色分配
```swift
func getConnectionColor(for destination: GeoPoint,
                        in destinations: [GeoPoint]) -> UIColor {
    guard let index = destinations.firstIndex(where: { $0.id == destination.id })
    else { return .blue }

    let colors: [UIColor] = [
        UIColor(hex: "#2196F3"),  // 蓝色
        UIColor(hex: "#4CAF50"),  // 绿色
        UIColor(hex: "#FF9800"),  // 橙色
        UIColor(hex: "#9C27B0"),  // 紫色
        UIColor(hex: "#F44336")   // 红色
    ]

    return colors[index % colors.count]
}
```

## 交互流程

### 1. 添加点位流程
```
用户点击加号/十字指示
  ↓
弹出"加点提示"对话框
  ↓
输入点名称
  ↓
选择所属案例
  ↓
选择点类型（原点/终点）
  ↓
检查数量限制
  ↓
检查重复终点（仅终点）
  ↓
保存点位
  ↓
更新地图显示
```

### 2. 原点选择流程
```
用户点击原点按钮
  ↓
显示当前案例原点列表
  ↓
用户选择一个原点
  ↓
罗盘切换为锁定模式
  ↓
相机移动到原点位置
  ↓
显示该原点的所有终点连线
```

### 3. 终点选择流程
```
用户点击终点按钮
  ↓
显示当前案例终点列表
  ↓
用户多选终点
  ↓
点击确定
  ↓
提示选择原点
  ↓
用户选择原点
  ↓
显示选定终点与原点的连线
```

## 测试验证清单

- [ ] 试用限制正常工作（最多2个案例）
- [ ] 每案例最多2个原点（不含GPS原点）
- [ ] 每案例最多5个终点
- [ ] GPS原点不计入原点配额
- [ ] 添加点位对话框正常显示
- [ ] 重复终点检测正常工作（300米阈值）
- [ ] 原点选择器正常工作
- [ ] 终点选择器正常工作（多选）
- [ ] 全选/清空按钮正常工作
- [ ] 案例管理页面正常显示
- [ ] 新建案例功能正常
- [ ] 案例展开/折叠正常
- [ ] 案例搜索功能正常
- [ ] 多终点连线颜色正确分配
- [ ] GPS原点坐标实时更新
- [ ] 当前案例自动切换正常

## 已知限制

- 不支持扇形搜索
- 不支持POI搜索
- 不支持十字准心模式
- 不支持生活圈模式

## 下一阶段预告

Phase 3 (V2.0.0) 将添加：
- 扇形区域搜索
- POI搜索与过滤
- 十字准心选点模式
- 搜索页面
