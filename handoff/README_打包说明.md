# TestFlight 打包说明

## 概述

本脚本用于构建 iOS 应用的 IPA 文件，供上传到 TestFlight 进行测试分发。

**新的应用信息：**
- Bundle ID: `com.fengshui.zohar.compass`
- SKU: `fengshui-compass-001`
- Apple ID: `6759500274`

---

## 前置条件

在运行脚本前，请确保你的 Mac 上已安装：

1. **Xcode 15.0+**
   ```bash
   xcode-select --install
   ```

2. **CocoaPods**
   ```bash
   sudo gem install cocoapods
   ```

3. **XcodeGen**
   ```bash
   brew install xcodegen
   ```

4. **Apple 开发者账号**
   - 拥有有效的 Apple Developer 账号
   - 已加入开发团队
   - 知道你的 **Team ID**（可在 [Apple Developer](https://developer.apple.com/account) 后台查看）

---

## 步骤 1：获取 Team ID

1. 访问 [Apple Developer Account](https://developer.apple.com/account)
2. 登录你的 Apple ID
3. 点击 **Membership** 或 **Team** 页面
4. 找到 **Team ID**（格式如 `XXXXXXXXXX`，10 个字符）
5. 复制这个 ID

---

## 步骤 2：编辑脚本配置

1. 打开 `handoff/build_ipa.sh`
2. 找到这一行：
   ```bash
   DEVELOPMENT_TEAM="XXXXXXXXXX"   # 你的 Team ID
   ```
3. 将 `XXXXXXXXXX` 替换为你的实际 Team ID
4. 保存文件

**示例：**
```bash
DEVELOPMENT_TEAM="U459WDD7N6"   # 你的 Team ID
```

脚本会把导出配置写到 `build/ExportOptions_AppStore.generated.plist`，不会修改仓库中的模板文件。

也可以不改文件，直接在运行时传入：

```bash
DEVELOPMENT_TEAM="U459WDD7N6" ./handoff/build_ipa.sh
```

---

## 步骤 3：运行脚本

1. 打开终端，进入项目根目录：
   ```bash
   cd /path/to/FengShuiLuopan_ios
   ```

2. 给脚本添加执行权限：
   ```bash
   chmod +x handoff/build_ipa.sh
   ```

3. 运行脚本：
   ```bash
   ./handoff/build_ipa.sh
   ```

4. 脚本会依次执行：
   - 生成 Xcode 项目（xcodegen）
   - 安装 CocoaPods 依赖
   - 构建 Archive
   - 导出 IPA 文件
   - 自动向 Xcode 请求下载或更新签名所需的描述文件

5. 等待完成（通常需要 5-10 分钟）

---

## 步骤 4：上传到 TestFlight

脚本完成后，IPA 文件位于：
```
build/export/FengShuiLuopan.ipa
```

### 方式 A：使用 Transporter（推荐）

1. 从 App Store 下载 [Transporter](https://apps.apple.com/app/transporter/id1450874784)
2. 打开 Transporter，点击 **+** 按钮
3. 选择 `build/export/FengShuiLuopan.ipa`
4. 点击 **Deliver**
5. 输入你的 Apple ID 和密码
6. 等待上传完成

### 方式 B：使用 Xcode Organizer

1. 打开 Xcode
2. 菜单 → **Window** → **Organizer**
3. 选择 **Archives** 标签
4. 找到最新的 Archive
5. 点击 **Distribute App**
6. 选择 **TestFlight**
7. 按提示完成上传

---

## 常见问题

### Q1: 脚本报错 "command not found: xcodegen"

**解决方案：**
```bash
brew install xcodegen
```

### Q2: 脚本报错 "command not found: pod"

**解决方案：**
```bash
sudo gem install cocoapods
```

### Q3: Archive 失败，提示签名错误

**可能原因：**
- Team ID 填写错误
- 你的 Apple 账号没有有效的开发者证书
- 当前 Mac 上的 Xcode 没有登录对应 Apple ID

**解决方案：**
1. 确认 Team ID 正确
2. 打开 Xcode，确认 `Settings -> Accounts` 已登录对应 Apple ID
3. 重新运行脚本

### Q4: 上传到 TestFlight 后，App Store Connect 显示"需要合规信息"

这是正常的。按照 App Store Connect 的提示填写合规信息即可。

### Q5: 脚本卡在某一步不动

通常是网络问题或依赖下载缓慢。可以：
1. 检查网络连接
2. 等待 5-10 分钟
3. 如果仍然卡住，按 `Ctrl+C` 中断，检查错误信息

---

## 脚本工作流程详解

```
1. xcodegen generate
   └─ 根据 project.yml 生成 FengShuiLuopan.xcodeproj

2. pod install
   └─ 安装 CocoaPods 依赖（AMap3DMap、AMapSearch）

3. xcodebuild archive
   └─ 编译并生成 .xcarchive 文件
   └─ 使用你的 Team ID 进行自动签名
   └─ 允许 Xcode 自动下载或更新描述文件

4. xcodebuild -exportArchive
   └─ 从 .xcarchive 导出 IPA 文件
   └─ 使用 ExportOptions_AppStore.plist 配置导出参数

5. 输出 IPA 到 build/export/
```

---

## 文件说明

| 文件 | 说明 |
|------|------|
| `handoff/build_ipa.sh` | 主打包脚本 |
| `handoff/ExportOptions_AppStore.plist` | IPA 导出配置 |
| `project.yml` | Xcode 项目配置（XcodeGen） |
| `Podfile` | CocoaPods 依赖配置 |

---

## 支持

如有问题，请：
1. 检查上述常见问题
2. 查看脚本输出的错误信息
3. 联系开发团队

---

**最后更新：2026-03-25**
