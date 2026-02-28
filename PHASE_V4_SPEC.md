# Phase 4 (V3.0.0) - 生活圈模式

## 版本目标

实现生活圈模式，帮助用户分析家、公司、日常场所三点之间的风水格局。

## 新增功能

### 1. 生活圈模式概述

#### 1.1 模式特性
- 生活圈模式与普通模式互斥
- 启用生活圈模式会自动存档普通模式当前案例和原点终点及其连线的显示状态
- 然后隐藏原点、终点和连线
- 在退出生活圈模式时自动恢复普通模式原点/终点显示及其连线
- 生活圈数据与普通模式项目数据独立存储

#### 1.2 三个角色
- **家（原点1）：** 罗盘尺寸最大
- **公司/工作地点（原点2）：** 罗盘尺寸中等
- **娱乐/常去场所（原点3）：** 罗盘尺寸最小

### 2. 激活生活圈模式

#### 2.1 进入流程
**触发方式：** 点击地图界面右上角"更多"菜单，选择"生活圈模式"按钮

**完整流程：** 见ARCHITECTURE.md 10.2节

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

#### 2.2 原点选择（多选模式）
**要求：** 必须选择3个原点

**选择方式：**
- 从现有堪舆案例中的现有原点选择
- 或在向导过程中点击"添加新位置"自动跳转到地图界面
- 通过点击屏幕中心的十字指示加点

### 3. 角色分配对话框

#### 3.1 对话框布局
```
┌─────────────────────────────────┐
│  生活圈角色分配                  │
├─────────────────────────────────┤
│  请为以下三个位置分配角色：       │
│                                 │
│  位置1: [原点名称1]             │
│  角色: [家 ▼]                   │
│                                 │
│  位置2: [原点名称2]             │
│  角色: [公司 ▼]                 │
│                                 │
│  位置3: [原点名称3]             │
│  角色: [日常场所 ▼]             │
│                                 │
│  💡 系统已根据名称智能推荐角色    │
├─────────────────────────────────┤
│  [取消] [确定]                  │
└─────────────────────────────────┘
```

#### 3.2 智能角色推荐算法
见ARCHITECTURE.md 10.5节

**关键词库：**
```swift
let homeKeywords = Set(["家", "住宅", "小区", "公寓", "楼盘", "房", "宅", "居"])
let workKeywords = Set(["公司", "办公", "工作", "单位", "企业", "写字楼", "厂", "店"])
let entertainmentKeywords = Set(["餐厅", "商场", "健身", "娱乐", "咖啡", "超市", "饭店"])
```

**匹配逻辑：**
1. 第一轮：明确匹配（某个类别得分显著高于其他）
2. 第二轮：为剩余原点分配剩余角色（按列表顺序）

#### 3.3 角色分配缓存
见ARCHITECTURE.md 10.6节

```swift
// Key: 原点ID集合（无序），Value: 角色映射
var roleAssignmentCache: [Set<Int>: [Int: LifeCirclePointType]] = [:]
// 生命周期：会话级别（MapView销毁时清空，防止跨案例污染）
```

**缓存逻辑：**
- 若缓存中有该3个原点的历史分配，直接使用
- 若缓存中没有，使用智能推荐算法
- 用户确认后保存到缓存

### 4. 生活圈显示

#### 4.1 地图显示
**完成加点后，地图会显示：**
1. 三个罗盘（分别位于生活圈加的三个点处）
   - 家：罗盘尺寸最大（1200x1200像素）
   - 公司：罗盘尺寸中等（1000x1000像素）
   - 日常场所：罗盘尺寸最小（800x800像素）
2. 三点连线（三角形）
3. 顶部横幅显示生活圈信息

#### 4.2 三角连线颜色编码
见ARCHITECTURE.md 10.4节

| 连线 | 颜色 | Hex |
|------|------|-----|
| 家 → 公司 | 绿色 | #00C853 |
| 公司 → 餐厅 | 蓝色 | #2196F3 |
| 餐厅 → 家 | 橙色 | #FF9800 |

#### 4.3 "指入"逻辑
见ARCHITECTURE.md 10.3节

**核心设计：** 每个罗盘上显示"指向它"的连线，而非"它指向"的连线。

| 罗盘 | 显示的连线 |
|------|-----------|
| 家 | 餐厅→家、公司→家 |
| 公司 | 家→公司、餐厅→公司 |
| 日常场所 | 公司→餐厅、家→餐厅 |

**标签格式：** `→来源名→ | 45.3° | 艮山 | 2.5km`

**示例：**
- 家的罗盘上显示：
  - `→餐厅→ | 135.2° | 巽山 | 3.2km`
  - `→公司→ | 45.8° | 艮山 | 5.1km`

### 5. 生活圈横幅

#### 5.1 横幅布局
```
┌─────────────────────────────────┐
│  🏠 生活圈模式  [详情] [退出]    │
└─────────────────────────────────┘
```

#### 5.2 横幅功能
**详情按钮：**
- 点击后弹出生活圈详情对话框
- 显示三点之间的详细信息：
  - 各点名称、坐标
  - 三条连线的距离、方位角、24山
  - 三角形面积（可选）

**退出按钮：**
- 点击后退出生活圈模式
- 自动恢复普通模式原点/终点显示及其连线

### 6. 生活圈数据持久化

#### 6.1 自动存储
- 生活圈数据会自动存储
- 下次打开应用自动恢复
- 未完成的向导进度也会保存，防止误关

#### 6.2 数据隔离
- 生活圈数据与普通模式项目数据独立存储
- 不会相互干扰

## UI布局更新

### 主界面布局（生活圈模式）
```
┌─────────────────────────────────┐
│  🏠 生活圈模式  [详情] [退出]    │  ← 顶部横幅
├─────────────────────────────────┤
│  [地图区域]                      │
│                                 │
│      🧭 (家-大)                 │
│                                 │
│                                 │
│  🧭 (公司-中)    🧭 (餐厅-小)   │
│                                 │
│  三角连线（三种颜色）             │
│                                 │
│  "指入"标签                     │
└─────────────────────────────────┘
```

### 角色分配对话框
```
┌─────────────────────────────────┐
│  生活圈角色分配                  │
├─────────────────────────────────┤
│  请为以下三个位置分配角色：       │
│                                 │
│  位置1: 我的家                  │
│  角色: [家 ▼] ✓ 智能推荐        │
│                                 │
│  位置2: XX公司                  │
│  角色: [公司 ▼] ✓ 智能推荐      │
│                                 │
│  位置3: 星巴克                  │
│  角色: [日常场所 ▼] ✓ 智能推荐  │
│                                 │
│  💡 系统已根据名称智能推荐角色    │
├─────────────────────────────────┤
│  [取消] [确定]                  │
└─────────────────────────────────┘
```

## 数据模型

### LifeCircleData
见ARCHITECTURE.md 10.1节

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

## 技术实现要点

### 1. 智能角色推荐算法

```swift
func recommendRoles(for origins: [GeoPoint]) -> [Int: LifeCirclePointType] {
    var scores: [Int: [LifeCirclePointType: Int]] = [:]

    // 计算每个原点对每个角色的匹配分数
    for origin in origins {
        let name = origin.name.lowercased()
        var roleScores: [LifeCirclePointType: Int] = [:]

        // 家的关键词匹配
        roleScores[.home] = homeKeywords.filter { name.contains($0) }.count

        // 公司的关键词匹配
        roleScores[.work] = workKeywords.filter { name.contains($0) }.count

        // 日常场所的关键词匹配
        roleScores[.entertainment] = entertainmentKeywords.filter {
            name.contains($0)
        }.count

        scores[origin.id] = roleScores
    }

    // 第一轮：明确匹配
    var assignments: [Int: LifeCirclePointType] = [:]
    var usedRoles: Set<LifeCirclePointType> = []

    for (originId, roleScores) in scores {
        let maxScore = roleScores.values.max() ?? 0
        if maxScore > 0 {
            let topRoles = roleScores.filter { $0.value == maxScore }
            if topRoles.count == 1,
               let role = topRoles.first?.key,
               !usedRoles.contains(role) {
                assignments[originId] = role
                usedRoles.insert(role)
            }
        }
    }

    // 第二轮：为剩余原点分配剩余角色
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
```

### 2. "指入"连线计算

```swift
func calculateIncomingConnections(
    for point: GeoPoint,
    in lifeCircle: LifeCircleData
) -> [LifeCircleConnection] {
    let allPoints = [
        lifeCircle.homePoint,
        lifeCircle.workPoint,
        lifeCircle.entertainmentPoint
    ]

    // 找到所有指向当前点的连线
    return allPoints
        .filter { $0.id != point.id }
        .map { fromPoint in
            let distance = FengShuiEngine.calculateVincentyDistance(
                from: fromPoint.coordinate,
                to: point.coordinate
            )
            let bearing = FengShuiEngine.calculateRhumbBearing(
                from: fromPoint.coordinate,
                to: point.coordinate
            )
            let shanName = FengShuiEngine.bearingToShan(bearing)

            return LifeCircleConnection(
                from: fromPoint,
                to: point,
                distance: distance,
                bearing: bearing,
                shanName: shanName
            )
        }
}
```

### 3. 罗盘尺寸管理

```swift
func getCompassSize(for pointType: LifeCirclePointType) -> CGSize {
    switch pointType {
    case .home:
        return CGSize(width: 1200, height: 1200)  // 最大
    case .work:
        return CGSize(width: 1000, height: 1000)  // 中等
    case .entertainment:
        return CGSize(width: 800, height: 800)    // 最小
    }
}
```

### 4. 三角连线绘制

```swift
func drawLifeCircleConnections(_ lifeCircle: LifeCircleData) {
    // 家 → 公司（绿色）
    drawConnection(
        from: lifeCircle.homePoint,
        to: lifeCircle.workPoint,
        color: UIColor(hex: "#00C853")
    )

    // 公司 → 餐厅（蓝色）
    drawConnection(
        from: lifeCircle.workPoint,
        to: lifeCircle.entertainmentPoint,
        color: UIColor(hex: "#2196F3")
    )

    // 餐厅 → 家（橙色）
    drawConnection(
        from: lifeCircle.entertainmentPoint,
        to: lifeCircle.homePoint,
        color: UIColor(hex: "#FF9800")
    )
}
```

## 交互流程

### 1. 激活生活圈模式流程
```
用户点击"更多"→"生活圈模式"
  ↓
原点选择器变为多选模式
  ↓
用户选择3个原点
  ↓
点击"确定"
  ↓
检查缓存：roleAssignmentCache[Set(id1,id2,id3)]
  ↓
有缓存？
  ├─ 是 → 显示历史分配
  └─ 否 → 智能推荐角色
  ↓
显示角色分配对话框
  ↓
用户确认或调整角色
  ↓
点击"确定"
  ↓
保存到缓存（会话级别）
  ↓
激活生活圈：
  ├─ 隐藏主功能罗盘和连线
  ├─ 创建3个不同尺寸罗盘
  ├─ 绘制三角连线（三种颜色）
  ├─ 计算"指入"连线信息
  └─ 显示 LifeCircleBanner
```

### 2. 退出生活圈模式流程
```
用户点击横幅"退出"按钮
  ↓
隐藏生活圈罗盘和连线
  ↓
恢复普通模式原点/终点显示
  ↓
恢复普通模式连线显示
  ↓
隐藏 LifeCircleBanner
```

## 测试验证清单

- [ ] "更多"菜单中"生活圈模式"按钮正常显示
- [ ] 点击后原点选择器变为多选模式
- [ ] 必须选择3个原点才能继续
- [ ] 角色分配对话框正常显示
- [ ] 智能角色推荐算法正确工作
- [ ] 关键词匹配正确
- [ ] 角色分配缓存正常工作
- [ ] 用户可以手动调整角色分配
- [ ] 三个罗盘尺寸正确（大、中、小）
- [ ] 三角连线颜色正确（绿、蓝、橙）
- [ ] "指入"连线信息正确显示
- [ ] 标签格式正确
- [ ] 生活圈横幅正常显示
- [ ] 详情按钮显示完整信息
- [ ] 退出按钮正常工作
- [ ] 退出后恢复普通模式状态
- [ ] 生活圈数据自动存储
- [ ] 下次打开应用自动恢复
- [ ] 未完成的向导进度保存正常
- [ ] 生活圈数据与普通模式数据隔离

## 已知限制

- 不支持新手指导
- 不支持使用说明
- 不支持地图SDK选择

## 下一阶段预告

Phase 5-6 (V4.0.0) 将添加：
- 新手指导系统
- 使用说明页面
- 地图SDK选择（高德/谷歌/自动检测）
- 区域自动切换提示
- 版本信息显示
