# Phase 5-6 (V4.0.0) - 新手指导与发布准备

## 版本目标

实现新手指导系统、使用说明页面、地图SDK选择功能，为App Store发布做准备。

## 新增功能

### 1. 新手指导系统

#### 1.1 触发时机
- 下载软件后第一次进入会触发新手指导
- 用户可以点击"下一步"逐步查看
- 用户可以点击"跳过"直接进入应用

#### 1.2 新手指导内容
**指导步骤（待细化）：**
1. 欢迎页面
   - 应用名称和Logo
   - 简短介绍："基于24山的专业风水方位测量工具"
2. GPS权限说明
   - 说明为什么需要GPS权限
   - 引导用户授予权限
3. 地图基础操作
   - 如何缩放地图
   - 如何切换地图类型
   - 十字指示的作用
4. 添加原点和终点
   - 如何添加原点
   - 如何添加终点
   - 连线信息的含义
5. 案例管理
   - 如何创建案例
   - 如何管理点位
6. 完成
   - 开始使用按钮

#### 1.3 新手指导UI
**页面布局：**
```
┌─────────────────────────────────┐
│                                 │
│  [指导内容区域]                  │
│                                 │
│  图片/动画演示                   │
│                                 │
│  文字说明                        │
│                                 │
├─────────────────────────────────┤
│  ● ○ ○ ○ ○ ○                   │  ← 进度指示器
├─────────────────────────────────┤
│  [跳过]              [下一步]   │
└─────────────────────────────────┘
```

#### 1.4 重置新手指导
- 在使用说明页面最底部有"重置新手指导"按钮
- 点击后下次进入软件会进行新手指导

### 2. 使用说明页面

#### 2.1 进入方式
**触发方式：** 在主界面下方菜单栏加入第四个按键"使用说明"按钮

**菜单栏更新：**
- [地图] [堪舆管理] [搜索] [使用说明]

#### 2.2 页面布局
```
┌─────────────────────────────────┐
│  使用说明                        │
├─────────────────────────────────┤
│  [可上下滑动查看]                │
│                                 │
│  ## 基础功能                    │
│  - 地图操作                     │
│  - 添加原点和终点                │
│  - 查看连线信息                  │
│                                 │
│  ## 高级功能                    │
│  - 扇形搜索                     │
│  - POI搜索                      │
│  - 生活圈模式                    │
│                                 │
│  ## 常见问题                    │
│  - Q: 如何添加多个原点？         │
│    A: ...                       │
│  - Q: 什么是24山？              │
│    A: ...                       │
│  - Q: 如何使用扇形搜索？         │
│    A: ...                       │
│                                 │
├─────────────────────────────────┤
│  版本信息：V4.0.0               │
│  [重置新手指导]                  │
└─────────────────────────────────┘
```

#### 2.3 使用说明内容（待细化）
**基础功能：**
- 地图操作（缩放、平移、切换类型）
- 添加原点和终点
- 查看连线信息（方位角、24山、距离）
- 罗盘锁定/解锁模式
- 定位按钮

**高级功能：**
- 案例管理
- 多原点多终点
- 扇形搜索
- POI搜索
- 十字准心选点
- 生活圈模式

**常见问题：**
- 如何添加多个原点？
- 什么是24山？
- 如何使用扇形搜索？
- 生活圈模式是什么？
- 为什么需要GPS权限？
- 如何切换地图SDK？

#### 2.4 版本信息
- 显示当前版本号
- 显示更新日志（可选）

### 3. 地图SDK选择

#### 3.1 设置入口
**触发方式：** 在主界面右上角"更多"菜单中，选择"设置"

**设置页面布局：**
```
┌─────────────────────────────────┐
│  设置                            │
├─────────────────────────────────┤
│  地图SDK选择                     │
│  ○ 自动检测 (推荐)              │
│     根据GPS位置、SIM卡等信息     │
│     自动选择最佳SDK              │
│  ○ 高德地图                     │
│  ○ 谷歌地图                     │
├─────────────────────────────────┤
│  区域自动切换                    │
│  ☑ 检测到跨境时自动提示切换      │
│     (仅在"自动检测"模式下可用)   │
├─────────────────────────────────┤
│  其他设置                        │
│  ...                            │
└─────────────────────────────────┘
```

#### 3.2 地图SDK选择功能
见ARCHITECTURE.md 4.2.5节

**三种模式：**
1. **自动检测（推荐）：**
   - 根据GPS位置、SIM卡等信息自动选择最佳SDK
   - 国内使用高德地图
   - 国外使用Google Maps
2. **高德地图：**
   - 强制使用高德地图
   - 适用于国内用户
3. **谷歌地图：**
   - 强制使用Google Maps
   - 适用于国外用户或有VPN的用户

#### 3.3 区域自动切换
**功能：**
- 仅在"自动检测"模式下可用
- 检测到跨境时自动提示切换
- 用户可以选择是否启用

**跨境检测逻辑：**
- 监听GPS位置变化
- 判断是否跨越国境线
- 若跨境，弹出提示："检测到您已跨境，是否切换地图SDK？"
- 用户可以选择"切换"或"取消"

#### 3.4 RegionDetector（预留）
见ARCHITECTURE.md 4.2.5节

**检测方式：**
1. GPS围栏坐标判断
2. SIM卡MCC判断
3. 系统语言/地区判断

**注意：** RegionDetector的具体实现细节推迟到V5，Phase 5-6仅实现基础的手动选择功能。

### 4. 发布准备

#### 4.1 App Store准备
**必需项：**
- [ ] 应用图标（1024x1024）
- [ ] 启动屏幕（LaunchScreen）
- [ ] 应用截图（多尺寸）
- [ ] 应用描述
- [ ] 关键词
- [ ] 隐私政策URL
- [ ] 支持URL

**可选项：**
- [ ] 应用预览视频
- [ ] 促销文本

#### 4.2 隐私合规
**必需项：**
- [ ] 隐私政策文档
- [ ] GPS权限使用说明（Info.plist）
- [ ] 高德SDK隐私合规配置
- [ ] 数据收集说明

**Info.plist配置：**
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>需要获取您的位置信息以显示罗盘和测量方位</string>

<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>需要获取您的位置信息以显示罗盘和测量方位</string>
```

#### 4.3 性能优化
**必需项：**
- [ ] 启动时间优化（< 2秒）
- [ ] 内存使用优化（< 100MB）
- [ ] 地图加载优化
- [ ] 罗盘渲染优化

#### 4.4 测试
**必需项：**
- [ ] 真机测试（iPhone X）
- [ ] 不同iOS版本测试（iOS 16.0+）
- [ ] GPS权限测试
- [ ] 地图SDK切换测试
- [ ] 新手指导测试
- [ ] 所有功能冒烟测试

## UI布局更新

### 主界面布局（完整版）
```
┌─────────────────────────────────┐
│  [更多 ▼]                       │  ← 右上角更多菜单
│                                 │     - 生活圈模式
│  [地图区域]                      │     - 设置 (新增)
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
│                                 │  - [⭕] 扇形搜索
├─────────────────────────────────┤
│  [地图] [堪舆管理] [搜索] [说明] │  ← 底部菜单栏 (新增说明)
└─────────────────────────────────┘
```

### 新手指导页面
```
┌─────────────────────────────────┐
│                                 │
│         [Logo]                  │
│                                 │
│  基于24山的专业风水方位测量工具  │
│                                 │
│  [开始使用]                     │
│                                 │
├─────────────────────────────────┤
│  ● ○ ○ ○ ○ ○                   │
├─────────────────────────────────┤
│  [跳过]              [下一步]   │
└─────────────────────────────────┘
```

### 设置页面
```
┌─────────────────────────────────┐
│  ← 设置                         │
├─────────────────────────────────┤
│  地图设置                        │
│  ────────────────────────────   │
│  地图SDK选择                     │
│  ○ 自动检测 (推荐)              │
│  ○ 高德地图                     │
│  ○ 谷歌地图                     │
│                                 │
│  ☑ 检测到跨境时自动提示切换      │
├─────────────────────────────────┤
│  关于                            │
│  ────────────────────────────   │
│  版本号: V4.0.0                 │
│  隐私政策                        │
│  使用条款                        │
└─────────────────────────────────┘
```

## 数据模型

### AppSettings
```swift
struct AppSettings {
    var mapSDKPreference: MapSDKPreference
    var autoSwitchOnCrossBorder: Bool
    var hasCompletedOnboarding: Bool
    var onboardingVersion: String
}

enum MapSDKPreference: String {
    case auto       // 自动检测
    case amap       // 高德地图
    case google     // 谷歌地图
}
```

### OnboardingStep
```swift
struct OnboardingStep {
    let id: Int
    let title: String
    let description: String
    let imageName: String?
    let animationName: String?
}
```

## 技术实现要点

### 1. 新手指导管理

```swift
class OnboardingManager {
    private let userDefaults = UserDefaults.standard
    private let onboardingVersionKey = "onboarding_version"
    private let currentVersion = "4.0.0"

    func shouldShowOnboarding() -> Bool {
        let completedVersion = userDefaults.string(forKey: onboardingVersionKey)
        return completedVersion != currentVersion
    }

    func markOnboardingCompleted() {
        userDefaults.set(currentVersion, forKey: onboardingVersionKey)
    }

    func resetOnboarding() {
        userDefaults.removeObject(forKey: onboardingVersionKey)
    }
}
```

### 2. 地图SDK选择

```swift
class MapSDKManager {
    private var currentSDK: MapSDKType = .amap
    private let settings: AppSettings

    func selectSDK() -> MapSDKType {
        switch settings.mapSDKPreference {
        case .auto:
            return detectBestSDK()
        case .amap:
            return .amap
        case .google:
            return .google
        }
    }

    private func detectBestSDK() -> MapSDKType {
        // 简化版检测逻辑（V5将实现完整的RegionDetector）
        let region = Locale.current.regionCode ?? "CN"
        return region == "CN" ? .amap : .google
    }

    func switchSDK(to newSDK: MapSDKType) {
        guard newSDK != currentSDK else { return }

        // 保存当前地图状态
        let currentState = saveMapState()

        // 切换SDK
        currentSDK = newSDK
        reinitializeMap(with: newSDK)

        // 恢复地图状态
        restoreMapState(currentState)
    }
}
```

### 3. 跨境检测（简化版）

```swift
class CrossBorderDetector {
    private var lastRegion: String?

    func checkCrossBorder(at coordinate: WGS84Coordinate) -> Bool {
        let currentRegion = detectRegion(at: coordinate)

        defer { lastRegion = currentRegion }

        guard let last = lastRegion else { return false }
        return last != currentRegion
    }

    private func detectRegion(at coordinate: WGS84Coordinate) -> String {
        // 简化版：仅判断中国大陆边界
        let isInChina = (
            coordinate.latitude >= 18.0 &&
            coordinate.latitude <= 54.0 &&
            coordinate.longitude >= 73.0 &&
            coordinate.longitude <= 135.0
        )
        return isInChina ? "CN" : "OTHER"
    }
}
```

## 交互流程

### 1. 首次启动流程
```
应用启动
  ↓
检查是否完成新手指导
  ↓
未完成？
  ├─ 是 → 显示新手指导
  │        ↓
  │      用户点击"下一步"或"跳过"
  │        ↓
  │      标记新手指导已完成
  │        ↓
  └─ 否 → 直接进入主界面
```

### 2. 地图SDK切换流程
```
用户进入设置页面
  ↓
选择地图SDK选项
  ↓
选择"自动检测"/"高德地图"/"谷歌地图"
  ↓
保存设置
  ↓
重新初始化地图
  ↓
恢复地图状态
```

### 3. 跨境提示流程
```
GPS位置更新
  ↓
检测是否跨境
  ↓
跨境？
  ├─ 是 → 检查"区域自动切换"设置
  │        ↓
  │      已启用？
  │        ├─ 是 → 弹出提示："检测到您已跨境，是否切换地图SDK？"
  │        │        ↓
  │        │      用户选择"切换"或"取消"
  │        │        ↓
  │        │      切换？
  │        │        ├─ 是 → 切换地图SDK
  │        │        └─ 否 → 继续使用当前SDK
  │        └─ 否 → 不提示
  └─ 否 → 继续
```

## 测试验证清单

- [ ] 首次启动显示新手指导
- [ ] 新手指导可以逐步查看
- [ ] 新手指导可以跳过
- [ ] 完成新手指导后不再显示
- [ ] 重置新手指导功能正常
- [ ] 使用说明页面正常显示
- [ ] 使用说明内容完整
- [ ] 常见问题解答清晰
- [ ] 版本信息正确显示
- [ ] 设置页面正常显示
- [ ] 地图SDK选择功能正常
- [ ] 自动检测模式正常工作
- [ ] 高德地图模式正常工作
- [ ] 谷歌地图模式正常工作（需VPN）
- [ ] 区域自动切换开关正常
- [ ] 跨境检测正常工作
- [ ] 跨境提示正常显示
- [ ] 地图SDK切换平滑无闪烁
- [ ] 切换后地图状态正确恢复
- [ ] 隐私政策链接正常
- [ ] GPS权限说明清晰
- [ ] 启动时间 < 2秒
- [ ] 内存使用 < 100MB
- [ ] 所有功能正常工作

## 发布检查清单

### App Store提交前
- [ ] 应用图标已准备（1024x1024）
- [ ] 启动屏幕已设计
- [ ] 应用截图已准备（多尺寸）
- [ ] 应用描述已撰写
- [ ] 关键词已选择
- [ ] 隐私政策已发布
- [ ] 支持URL已设置
- [ ] Info.plist配置完整
- [ ] 高德SDK隐私合规已配置
- [ ] 所有功能测试通过
- [ ] 真机测试通过
- [ ] 性能测试通过
- [ ] 内存泄漏检查通过
- [ ] 崩溃测试通过

### 可选项
- [ ] 应用预览视频已制作
- [ ] 促销文本已撰写
- [ ] TestFlight测试已完成
- [ ] 用户反馈已收集

## 已知限制

- RegionDetector仅实现简化版，完整版推迟到V5
- Google Maps SDK仅预留接口，完整实现推迟到V5
- 跨境检测仅基于简单的经纬度判断，未使用GPS围栏和SIM卡MCC

## 下一阶段预告

Phase V5.0.0（远期）将添加：
- Google Maps SDK完整实现
- RegionDetector完整实现（GPS围栏、SIM卡MCC判断）
- 云端同步功能（可选）
- 注册码系统
- 更多高级功能
