# iOS 自动签名和构建完整配置指南

> 本指南整合了 Team ID 提取、GitHub Secrets 配置、Xcode 项目自动创建的完整流程

---

## 📋 前置条件

确保你已经有以下文件：
- ✅ `FengShuiLuopan_ios.p12` - 开发证书
- ✅ `FengShuiLuopan_Dev.mobileprovision` - 配置文件
- ✅ 证书密码: `Hp15099837787!`

---

## 🚀 快速开始（3步完成）

### 第1步：提取 Team ID 并更新配置

在项目根目录运行：

```powershell
# 自动提取 Team ID 并更新 ExportOptions.plist
.\update_team_id.ps1
```

**预期输出：**
```
=== iOS Team ID 自动更新工具 ===

[1/3] 正在提取 Team ID...
      ✓ Team ID: XXXXXXXXXX
[2/3] 正在更新 ExportOptions.plist...
      ✓ 已更新 Team ID
[3/3] 验证更新结果...
      ✓ 验证成功!

=== 更新完成 ===
Team ID: XXXXXXXXXX
```

### 第2步：生成 Base64 编码

```powershell
# 生成证书和配置文件的 Base64 编码
.\generate_base64.ps1
```

**预期输出：**
```
=== iOS 签名文件 Base64 编码工具 ===

[1/2] 正在编码证书...
      ✓ 证书编码完成
[2/2] 正在编码配置文件...
      ✓ 配置文件编码完成

=== 编码完成 ===
已生成文件:
  - certificate_base64.txt
  - provision_base64.txt
```

### 第3步：配置 GitHub Secrets

1. 打开 GitHub 仓库页面
2. 进入 **Settings** → **Secrets and variables** → **Actions**
3. 点击 **New repository secret**，添加以下 4 个 Secrets：

| Secret 名称 | 值来源 | 说明 |
|------------|--------|------|
| `IOS_CERTIFICATE_BASE64` | `certificate_base64.txt` 的内容 | 开发证书 Base64 |
| `IOS_CERTIFICATE_PASSWORD` | `Hp15099837787!` | 证书密码 |
| `IOS_PROVISION_PROFILE_BASE64` | `provision_base64.txt` 的内容 | 配置文件 Base64 |
| `KEYCHAIN_PASSWORD` | 任意强密码（如 `Actions@2024!`） | GitHub Actions 临时 Keychain 密码 |

---

## ✅ 验证配置

### 提交并推送代码

```bash
git add ExportOptions.plist
git commit -m "chore: 更新 Team ID 和 iOS 签名配置"
git push
```

### 查看构建状态

1. 进入 GitHub 仓库的 **Actions** 标签页
2. 查看最新的 workflow 运行状态
3. 如果成功，会生成 `FengShuiLuopan.ipa` 文件

---

## 📦 工作流程说明

GitHub Actions 会自动执行以下步骤：

1. **创建 Xcode 项目结构**
   - 自动生成 `FengShuiLuopan.xcodeproj`
   - 配置 Bundle ID: `com.fengshuizohar.ios.dev`
   - 设置最低版本: iOS 16.0

2. **导入证书和配置文件**
   - 从 GitHub Secrets 解码证书
   - 创建临时 Keychain
   - 安装配置文件

3. **构建和签名**
   - 运行 `xcodebuild archive`
   - 使用 `ExportOptions.plist` 导出 IPA
   - 上传构建产物

4. **产物下载**
   - IPA 文件: `FengShuiLuopan.ipa`
   - dSYM 文件: `FengShuiLuopan.app.dSYM.zip`

---

## 🛠️ 手动操作（可选）

### 仅提取 Team ID（不更新文件）

```powershell
.\extract_team_id.ps1
```

输出会保存到 `team_id.txt`

### 手动更新 ExportOptions.plist

打开 `ExportOptions.plist`，找到：

```xml
<key>teamID</key>
<string>YOUR_TEAM_ID</string>
```

替换为你的 Team ID。

---

## 🔍 故障排查

### 问题1: "无法提取 Team ID"

**原因**: 配置文件路径错误或文件损坏

**解决方案**:
```powershell
# 检查文件是否存在
Test-Path "E:\FengShuiLuopan_ios\FengShuiLuopan_Dev.mobileprovision"
```

### 问题2: GitHub Actions 构建失败

**检查清单**:
- [ ] 4 个 GitHub Secrets 是否都已添加
- [ ] Base64 编码是否完整（没有换行符）
- [ ] Team ID 是否已更新到 `ExportOptions.plist`

**查看日志**:
1. 进入 Actions 标签页
2. 点击失败的 workflow
3. 查看具体错误信息

### 问题3: "Code signing failed"

**可能原因**:
- 证书密码错误
- 配置文件与 Bundle ID 不匹配
- Team ID 错误

**解决方案**:
1. 验证证书密码: `Hp15099837787!`
2. 确认 Bundle ID: `com.fengshuizohar.ios.dev`
3. 重新运行 `update_team_id.ps1`

---

## 📚 相关文档

- [QUICK_START_SIGNING.md](QUICK_START_SIGNING.md) - 快速参考清单
- [IOS_SIGNING_GUIDE.md](IOS_SIGNING_GUIDE.md) - 详细操作指南
- [GITHUB_SECRETS_GUIDE.md](GITHUB_SECRETS_GUIDE.md) - Secrets 配置说明

---

## 🔐 安全注意事项

1. **不要提交敏感文件到 Git**
   - ✅ `.gitignore` 已配置排除 `.p12`, `.mobileprovision`, `*_base64.txt`

2. **保护 GitHub Secrets**
   - ✅ Secrets 只在 GitHub Actions 中可见
   - ✅ 不会出现在日志中

3. **定期更新证书**
   - 开发证书有效期通常为 1 年
   - 配置文件有效期通常为 1 年

---

## ✨ 下一步

配置完成后，每次推送代码到 `main` 分支，GitHub Actions 会自动：
1. 创建 Xcode 项目
2. 构建并签名 IPA
3. 上传构建产物

你可以在 Actions 标签页下载 IPA 文件进行测试。
