# 项目目录结构创建指南

> 本文档指导在云Mac上创建完整的Xcode项目目录结构
> 见 ARCHITECTURE.md 5节 - 项目结构

## 1. 目录结构概览

```
FengShuiLuopan/
├── FengShuiLuopan/              # 主应用目录
│   ├── App/                     # 应用入口
│   │   ├── FengShuiLuopanApp.swift
│   │   └── AppDelegate.swift
│   ├── Core/                    # 核心层 (从POC迁移)
│   │   ├── Models/
│   │   │   ├── WGS84Coordinate.swift
│   │   │   ├── Mountain.swift
│   │   │   ├── Trigram.swift
│   │   │   └── WuXing.swift
│   │   ├── Engine/
│   │   │   ├── FengShuiEngine.swift
│   │   │   └── CoordinateConverter.swift
│   │   └── Database/
│   │       ├── DatabaseManager.swift
│   │       └── Migrations/
│   ├── Features/                # 功能模块
│   │   ├── Map/
│   │   │   ├── Views/
│   │   │   │   ├── MapView.swift
│   │   │   │   └── CompassOverlay.swift
│   │   │   ├── ViewModels/
│   │   │   │   └── MapViewModel.swift
│   │   │   └── Controllers/
│   │   │       ├── MapControllerProtocol.swift
│   │   │       └── GaodeMapController.swift
│   │   ├── Cases/               # 案例管理 (Phase 1)
│   │   ├── Origins/             # 原点管理 (Phase 1)
│   │   └── POI/                 # POI搜索 (Phase 2)
│   ├── Shared/                  # 共享组件
│   │   ├── Views/
│   │   ├── Extensions/
│   │   └── Utils/
│   └── Resources/               # 资源文件
│       ├── Assets.xcassets/
│       │   ├── compass.imageset/
│       │   └── Colors/
│       └── Localizable.strings
├── FengShuiLuopanTests/         # 单元测试
└── FengShuiLuopanUITests/       # UI测试
```

## 2. 创建步骤

### 2.1 在Xcode中创建项目
1. 打开Xcode
2. File → New → Project
3. 选择 "iOS" → "App"
4. 配置:
   - Product Name: `FengShuiLuopan`
   - Team: 选择你的开发团队
   - Organization Identifier: `com.yourcompany`
   - Bundle Identifier: `com.yourcompany.FengShuiLuopan`
   - Interface: `SwiftUI`
   - Language: `Swift`
   - Storage: `None` (我们使用SQLite.swift)
   - Include Tests: ✓
5. 保存到 `E:\FengShuiLuopan_ios\` (如果在云Mac上，保存到对应位置)

### 2.2 配置Info.plist
1. 将根目录的 `Info.plist` 内容复制到项目的Info.plist
2. 或在Xcode中手动添加权限说明

### 2.3 安装CocoaPods依赖
```bash
cd FengShuiLuopan_ios
pod install
```

之后始终使用 `FengShuiLuopan.xcworkspace` 打开项目（不是.xcodeproj）

### 2.4 添加SQLite.swift (SPM)
1. 在Xcode中: File → Add Package Dependencies
2. 输入URL: `https://github.com/stephencelis/SQLite.swift`
3. Version: `0.15.3` (或最新稳定版)
4. Add to Target: `FengShuiLuopan`

### 2.5 创建目录结构
在Xcode的Project Navigator中:
1. 右键 `FengShuiLuopan` → New Group
2. 按照上述结构创建所有文件夹
3. 注意: Xcode的Group对应文件系统的文件夹

### 2.6 迁移POC代码
将以下文件从 `POC_Algorithm/Sources/` 复制到对应位置:
- `Models/WGS84Coordinate.swift` → `Core/Models/`
- `Core/FengShuiEngine.swift` → `Core/Engine/`
- `Core/CoordinateConverter.swift` → `Core/Engine/`
- `Core/Mountain.swift` → `Core/Models/`
- `Core/Trigram.swift` → `Core/Models/`
- `Core/WuXing.swift` → `Core/Models/`

**注意**: 删除 `main.swift` 中的测试代码，测试应移到 `FengShuiLuopanTests/`

## 3. 验证清单

创建完成后，验证以下内容:
- [ ] Xcode项目可以正常打开
- [ ] CocoaPods依赖已安装 (Pods/ 目录存在)
- [ ] SQLite.swift已添加到项目
- [ ] Info.plist包含位置权限说明
- [ ] 所有POC代码文件已迁移
- [ ] 项目可以编译 (Cmd+B)
- [ ] 没有编译错误

## 4. 下一步

项目初始化完成后:
1. 创建 `FengShuiLuopanApp.swift` (应用入口)
2. 创建 `MapView.swift` (地图视图)
3. 集成高德地图SDK
4. 实现Phase 0功能

## 5. 常见问题

### Q: CocoaPods安装失败
A: 确保已安装CocoaPods: `sudo gem install cocoapods`

### Q: 高德SDK编译错误
A: 检查 `ENABLE_BITCODE` 是否设置为 `NO`

### Q: SQLite.swift找不到
A: 确保使用 `.xcworkspace` 打开项目，不是 `.xcodeproj`

### Q: 位置权限不生效
A: 检查Info.plist中的 `NSLocationWhenInUseUsageDescription` 是否存在
