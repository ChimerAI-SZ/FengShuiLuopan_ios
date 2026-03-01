# iOS自动签名编译完整指南

## 📋 前置条件

- ✅ iOS开发证书：`FengShuiLuopan_ios.p12`
- ✅ 配置文件：`FengShuiLuopan_Dev.mobileprovision`
- ✅ 证书密码：`Hp15099837787!`
- ✅ Bundle ID：`com.fengshuizohar.ios.dev`

## 🚀 快速开始

### 步骤1：生成Base64编码

在PowerShell中执行：

```powershell
cd E:\FengShuiLuopan_ios
.\generate_base64.ps1
```

执行后会生成两个文件：
- `certificate_base64.txt` - 证书的Base64编码
- `provision_base64.txt` - 配置文件的Base64编码

### 步骤2：配置GitHub Secrets

访问：https://github.com/ChimerAI-SZ/FengShuiLuopan_ios/settings/secrets/actions

添加以下4个Secrets：

| Secret名称 | 值 | 说明 |
|-----------|---|------|
| `IOS_CERTIFICATE_BASE64` | certificate_base64.txt的内容 | 证书Base64 |
| `IOS_CERTIFICATE_PASSWORD` | `Hp15099837787!` | 证书密码 |
| `IOS_PROVISION_PROFILE_BASE64` | provision_base64.txt的内容 | 配置文件Base64 |
| `KEYCHAIN_PASSWORD` | `actions_temp_password` | 临时keychain密码 |

### 步骤3：更新ExportOptions.plist

打开 `ExportOptions.plist`，将 `YOUR_TEAM_ID` 替换为你的Apple Team ID。

查找Team ID的方法：
1. 打开配置文件 `FengShuiLuopan_Dev.mobileprovision`
2. 搜索 `<key>TeamIdentifier</key>`
3. 下一行的字符串就是Team ID

或者使用命令：
```bash
security find-identity -v -p codesigning
```

### 步骤4：创建完整的Xcode项目

⚠️ **重要**：GitHub Actions需要完整的Xcode项目文件才能构建。

在本地Mac上：

1. 打开Xcode
2. 创建新项目或打开现有项目
3. 配置项目设置：
   - Bundle Identifier: `com.fengshuizohar.ios.dev`
   - Team: 选择你的开发团队
   - Signing: Manual
   - Provisioning Profile: FengShuiLuopan Dev

4. 确保项目包含以下文件：
   - `FengShuiLuopan.xcodeproj/` 或 `FengShuiLuopan.xcworkspace/`
   - `Podfile`
   - `Info.plist`
   - 所有Swift源文件

5. 提交到Git：
```bash
git add FengShuiLuopan.xcodeproj
git add FengShuiLuopan.xcworkspace  # 如果使用CocoaPods
git commit -m "feat: 添加Xcode项目文件"
git push
```

### 步骤5：触发构建

推送代码后，GitHub Actions会自动触发构建：

```bash
git add .
git commit -m "ci: 配置iOS自动签名"
git push
```

或者手动触发：
1. 访问：https://github.com/ChimerAI-SZ/FengShuiLuopan_ios/actions
2. 选择 "iOS Build with Signing"
3. 点击 "Run workflow"

### 步骤6：下载IPA

构建成功后：
1. 进入Actions页面
2. 点击最新的workflow运行
3. 在 "Artifacts" 部分下载：
   - `FengShuiLuopan-IPA` - 安装包
   - `FengShuiLuopan-dSYM` - 调试符号

## 📁 文件说明

### 新增文件

1. **generate_base64.ps1**
   - PowerShell脚本，用于生成Base64编码
   - 执行后生成 certificate_base64.txt 和 provision_base64.txt

2. **ExportOptions.plist**
   - IPA导出配置文件
   - 包含签名和配置文件信息

3. **.github/workflows/ios-build-signed.yml**
   - GitHub Actions workflow文件
   - 包含完整的签名和构建流程

4. **GITHUB_SECRETS_GUIDE.md**
   - GitHub Secrets配置指南

5. **IOS_SIGNING_GUIDE.md**（本文件）
   - 完整的操作指南

### 临时文件（不要提交到Git）

- `certificate_base64.txt` - 证书Base64（敏感信息）
- `provision_base64.txt` - 配置文件Base64（敏感信息）
- `FengShuiLuopan_ios.p12` - 证书文件（敏感信息）
- `FengShuiLuopan_Dev.mobileprovision` - 配置文件（敏感信息）

这些文件已在 `.gitignore` 中排除。

## 🔧 故障排查

### 问题1：证书导入失败

**错误信息**：`security: SecKeychainItemImport: The specified item already exists in the keychain.`

**解决方法**：
- 检查证书密码是否正确
- 确保Base64编码没有多余的空格或换行
- 重新生成Base64编码

### 问题2：配置文件UUID不匹配

**错误信息**：`error: No profiles for 'com.fengshuizohar.ios.dev' were found`

**解决方法**：
- 确认Bundle ID正确
- 检查配置文件是否过期
- 重新下载配置文件

### 问题3：Team ID错误

**错误信息**：`error: No signing certificate "iOS Development" found`

**解决方法**：
- 在ExportOptions.plist中填写正确的Team ID
- 确认证书和配置文件匹配

### 问题4：Xcode项目不存在

**错误信息**：`xcodebuild: error: 'FengShuiLuopan.xcworkspace' does not exist`

**解决方法**：
- 在本地创建完整的Xcode项目
- 提交项目文件到Git仓库
- 确保 `.xcodeproj` 或 `.xcworkspace` 文件存在

## 📝 注意事项

1. **安全性**
   - 不要将证书、配置文件、Base64编码提交到Git
   - 使用GitHub Secrets存储敏感信息
   - 定期更新证书和配置文件

2. **证书有效期**
   - 开发证书有效期通常为1年
   - 配置文件有效期通常为1年
   - 到期前需要重新生成并更新Secrets

3. **构建限制**
   - GitHub Actions免费版每月2000分钟
   - macOS runner消耗10倍分钟数
   - 建议只在必要时触发构建

4. **IPA安装**
   - 开发版IPA只能安装在注册的设备上
   - 需要通过Xcode、TestFlight或第三方工具安装
   - 不能直接在App Store分发

## 🎯 下一步

1. ✅ 完成Base64编码生成
2. ✅ 配置GitHub Secrets
3. ✅ 更新ExportOptions.plist中的Team ID
4. ⏳ 在本地创建完整的Xcode项目
5. ⏳ 提交项目文件到Git
6. ⏳ 触发GitHub Actions构建
7. ⏳ 下载并测试IPA

## 📚 参考资料

- [GitHub Actions文档](https://docs.github.com/en/actions)
- [Xcode构建文档](https://developer.apple.com/documentation/xcode)
- [代码签名指南](https://developer.apple.com/support/code-signing/)
- [配置文件管理](https://developer.apple.com/account/resources/profiles/list)

---

最后更新：2026-03-01
