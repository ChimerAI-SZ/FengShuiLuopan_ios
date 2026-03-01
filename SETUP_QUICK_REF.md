# 🚀 iOS 自动签名配置 - 快速参考卡

## 📝 3步完成配置

### 步骤1️⃣: 提取并更新 Team ID
```powershell
.\update_team_id.ps1
```
✅ 自动提取 Team ID 并更新 ExportOptions.plist

---

### 步骤2️⃣: 生成 Base64 编码
```powershell
.\generate_base64.ps1
```
✅ 生成 `certificate_base64.txt` 和 `provision_base64.txt`

---

### 步骤3️⃣: 配置 GitHub Secrets

进入 GitHub 仓库 → **Settings** → **Secrets and variables** → **Actions**

添加 4 个 Secrets:

| Secret 名称 | 值 |
|------------|-----|
| `IOS_CERTIFICATE_BASE64` | `certificate_base64.txt` 的内容 |
| `IOS_CERTIFICATE_PASSWORD` | `Hp15099837787!` |
| `IOS_PROVISION_PROFILE_BASE64` | `provision_base64.txt` 的内容 |
| `KEYCHAIN_PASSWORD` | 任意强密码（如 `Actions@2024!`） |

---

## ✅ 提交代码

```bash
git add ExportOptions.plist
git commit -m "chore: 更新 Team ID"
git push
```

---

## 🎯 验证构建

1. 进入 GitHub 仓库的 **Actions** 标签页
2. 查看 "iOS Build with Signing" workflow
3. 下载构建产物: `FengShuiLuopan.ipa`

---

## 🔧 故障排查

### 构建失败？

**检查清单:**
- [ ] 4 个 GitHub Secrets 都已添加
- [ ] Base64 内容完整（无换行符）
- [ ] Team ID 已更新到 ExportOptions.plist
- [ ] 证书密码正确: `Hp15099837787!`

**查看详细日志:**
GitHub Actions → 点击失败的 workflow → 查看错误信息

---

## 📚 详细文档

- [COMPLETE_SETUP_GUIDE.md](COMPLETE_SETUP_GUIDE.md) - 完整配置指南
- [IOS_SIGNING_GUIDE.md](IOS_SIGNING_GUIDE.md) - 详细操作步骤
- [QUICK_START_SIGNING.md](QUICK_START_SIGNING.md) - 快速开始

---

## 🎉 完成后

每次推送代码到 `main` 分支，GitHub Actions 会自动:
1. ✅ 创建 Xcode 项目
2. ✅ 构建并签名 IPA
3. ✅ 上传构建产物

**Bundle ID**: `com.fengshuizohar.ios.dev`
**最低版本**: iOS 16.0
**签名方式**: Manual (Development)
