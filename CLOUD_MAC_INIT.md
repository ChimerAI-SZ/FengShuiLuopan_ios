# 云Mac初始化操作指南

> 本文档提供在云Mac上执行项目初始化的完整步骤清单
> 执行前确保所有配置文件已从Windows推送到GitHub

## 前置条件

- [ ] 已将所有文件推送到GitHub仓库
- [ ] 云Mac已安装Xcode (14.0+)
- [ ] 云Mac已安装CocoaPods (`sudo gem install cocoapods`)
- [ ] 云Mac已配置Apple Developer账号

## 操作步骤

### 1. 克隆仓库
```bash
cd ~/Desktop
git clone https://github.com/ChimerAI-SZ/FengShuiLuopan_ios.git
cd FengShuiLuopan_ios
```

### 2. 创建Xcode项目
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
   - Storage: `None`
   - Include Tests: ✓
5. 保存到当前目录 (`~/Desktop/FengShuiLuopan_ios/`)

### 3. 替换Info.plist
```bash
# 备份Xcode生成的Info.plist
mv FengShuiLuopan/Info.plist FengShuiLuopan/Info.plist.backup

# 使用我们准备的Info.plist
cp Info.plist FengShuiLuopan/Info.plist
```

### 4. 安装CocoaPods依赖
```bash
pod install
```

**重要**: 之后始终使用 `FengShuiLuopan.xcworkspace` 打开项目

### 5. 添加SQLite.swift (SPM)
1. 打开 `FengShuiLuopan.xcworkspace`
2. File → Add Package Dependencies
3. 输入URL: `https://github.com/stephencelis/SQLite.swift`
4. Version: `0.15.3` (或最新稳定版)
5. Add to Target: `FengShuiLuopan`

### 6. 添加Core层文件到Xcode
1. 在Project Navigator中右键 `FengShuiLuopan` → Add Files to "FengShuiLuopan"
2. 选择 `FengShuiLuopan/Core/` 整个文件夹
3. 确保勾选:
   - ✓ Copy items if needed
   - ✓ Create groups
   - ✓ Add to targets: FengShuiLuopan

### 7. 验证编译
```bash
# 在Xcode中按 Cmd+B 编译
# 或使用命令行:
xcodebuild -workspace FengShuiLuopan.xcworkspace \
           -scheme FengShuiLuopan \
           -configuration Debug \
           build
```

### 8. 提交到Git
```bash
git add .
git commit -m "chore: 初始化Xcode项目和CocoaPods依赖"
git push origin main
```

## 验证清单

完成后检查:
- [ ] `FengShuiLuopan.xcworkspace` 存在
- [ ] `Pods/` 目录存在
- [ ] 高德SDK已安装 (Pods/AMap3DMap)
- [ ] SQLite.swift已添加到项目
- [ ] Core层所有文件在Xcode中可见
- [ ] 项目可以编译成功 (Cmd+B)
- [ ] 没有编译错误或警告

## 常见问题

### Q: pod install失败
```bash
# 更新CocoaPods仓库
pod repo update

# 清理缓存重试
pod cache clean --all
pod install
```

### Q: Xcode找不到SQLite.swift
- 确保使用 `.xcworkspace` 打开，不是 `.xcodeproj`
- File → Packages → Resolve Package Versions

### Q: 编译错误 "Bitcode not supported"
- 检查Podfile的post_install脚本是否正确执行
- 手动设置: Build Settings → Enable Bitcode → No

### Q: 高德SDK初始化失败
- 检查Info.plist中的 `AMapApiKey` 是否正确
- 检查Bundle Identifier是否与高德控制台配置一致

## 下一步

初始化完成后:
1. 创建应用入口文件 ([FengShuiLuopanApp.swift](FengShuiLuopan/App/FengShuiLuopanApp.swift))
2. 创建地图视图 ([MapView.swift](FengShuiLuopan/Features/Map/Views/MapView.swift))
3. 集成高德地图SDK
4. 开始Phase 0开发

## 预计时间

- 克隆仓库: 1分钟
- 创建Xcode项目: 2分钟
- 安装依赖: 3-5分钟
- 添加文件: 2分钟
- 验证编译: 1分钟

**总计**: 约10-15分钟
