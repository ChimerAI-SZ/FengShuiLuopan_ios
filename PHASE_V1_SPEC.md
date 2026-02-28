# Phase 1 (V0.5.0) - GPS原点与罗盘模式

## 版本目标

在Phase 0基础上，添加GPS原点、罗盘锁定/解锁模式、定位按钮。

## 新增功能

### 1. 定位按钮

#### 1.1 按钮位置
- 地图页面右侧按键区

#### 1.2 按钮功能
- 点击后屏幕中心移动到当前位置
- 对准屏幕中心的小十字
- 该十字在地图界面一直固定在地图中心

### 2. 罗盘锁定/解锁模式

#### 2.1 模式切换按钮
- 位置：地图页面右侧按键区
- 功能：切换罗盘的锁定模式和解锁模式

#### 2.2 锁定模式
- 罗盘固定在当前位置
- 罗盘所在点在地图上的位置不随地图移动而移动
- 罗盘位置锁定在地理坐标上

#### 2.3 解锁模式
- 罗盘固定在屏幕中央
- 地图移动会改变罗盘相对于地图的位置
- 罗盘位置跟随屏幕中心

### 3. GPS原点（预留）

#### 3.1 GPS原点特性
- 系统自动创建，不可删除/重命名
- 坐标随GPS定位实时更新
- 不占用用户原点配额（试用限制不计算）
- 每个案例可以有一个GPS原点
- 固定标识：`GPS_ORIGIN_ID = "gps_location_origin"`

**注意：** GPS原点的完整实现在Phase 2，Phase 1仅预留数据模型和接口。

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
│                                 │  - [📍] 定位按钮 (新增)
│                                 │  - [🔒/🔓] 罗盘模式 (新增)
└─────────────────────────────────┘
```

## 技术实现要点

### 1. 罗盘模式管理

#### 1.1 状态定义
```swift
enum CompassMode {
    case locked    // 锁定模式：罗盘固定在地理坐标
    case unlocked  // 解锁模式：罗盘固定在屏幕中心
}
```

#### 1.2 模式切换逻辑
```swift
func toggleCompassMode() {
    switch currentMode {
    case .locked:
        // 切换到解锁模式
        currentMode = .unlocked
        // 将罗盘从GroundOverlay改为屏幕中心的UIView
        removeGroundOverlay()
        addCompassView(at: screenCenter)

    case .unlocked:
        // 切换到锁定模式
        currentMode = .locked
        // 将罗盘从UIView改为GroundOverlay
        removeCompassView()
        let coordinate = mapView.centerCoordinate
        addGroundOverlay(at: coordinate)
    }
}
```

### 2. 定位按钮实现

#### 2.1 定位逻辑
```swift
func onLocationButtonTapped() {
    guard let userLocation = locationManager.location else {
        showToast("无法获取当前位置", priority: .high)
        return
    }

    // 移动相机到用户位置
    mapController.moveCamera(
        to: userLocation.coordinate,
        zoom: 16,
        animated: true,
        source: .locationButton
    )
}
```

#### 2.2 相机优先级
- 定位按钮触发的相机移动优先级：`.locationButton` (Level 3)
- 见ARCHITECTURE.md 4.4节相机优先级系统

### 3. GPS原点数据模型（预留）

```swift
struct GPSOrigin {
    let id: String = "gps_location_origin"  // 固定ID
    var coordinate: WGS84Coordinate         // 实时更新
    let name: String = "当前位置"           // 固定名称
    let isSystemGenerated: Bool = true      // 系统生成标记
}
```

## 交互流程

### 1. 定位按钮流程
```
用户点击定位按钮
  ↓
检查GPS权限
  ↓
获取当前位置
  ↓
移动地图中心到当前位置
  ↓
十字指示对准当前位置
```

### 2. 罗盘模式切换流程
```
用户点击罗盘模式按钮
  ↓
判断当前模式
  ↓
锁定模式 → 解锁模式：
  - 移除GroundOverlay
  - 添加屏幕中心UIView
  - 罗盘跟随屏幕中心
  ↓
解锁模式 → 锁定模式：
  - 移除UIView
  - 添加GroundOverlay
  - 罗盘锁定在地理坐标
```

## 测试验证清单

- [ ] 定位按钮点击后地图中心移动到当前位置
- [ ] 无GPS权限时定位按钮显示提示
- [ ] 罗盘模式切换按钮正常工作
- [ ] 锁定模式下罗盘固定在地理坐标
- [ ] 解锁模式下罗盘固定在屏幕中心
- [ ] 锁定模式下拖动地图，罗盘不跟随屏幕移动
- [ ] 解锁模式下拖动地图，罗盘跟随屏幕中心
- [ ] 模式切换时罗盘位置平滑过渡
- [ ] 相机优先级系统正常工作

## 已知限制

- 仍仅支持单原点单终点
- 不支持案例管理
- GPS原点仅预留接口，未完整实现

## 下一阶段预告

Phase 2 (V1.0.0) 将添加：
- 多原点（≤2）多终点（≤5）
- 案例管理系统
- 原点/终点选择器
- GPS原点完整实现
- 试用限制（最多2个案例）
