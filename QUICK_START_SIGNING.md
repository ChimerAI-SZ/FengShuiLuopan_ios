# iOS自动签名配置 - 快速操作清单 ✅

## 第1步：生成Base64编码

在PowerShell中执行：

```powershell
cd E:\FengShuiLuopan_ios
.\generate_base64.ps1
```

✅ 完成后会生成两个文件：
- `certificate_base64.txt`
- `provision_base64.txt`

---

## 第2步：配置GitHub Secrets

访问：https://github.com/ChimerAI-SZ/FengShuiLuopan_ios/settings/secrets/actions

点击 "New repository secret"，依次添加：

### Secret 1
- **名称**: `IOS_CERTIFICATE_BASE64`
- **值**: 打开 `certificate_base64.txt`，复制全部内容

### Secret 2
- **名称**: `IOS_CERTIFICATE_PASSWORD`
- **值**: `Hp15099837787!`

### Secret 3
- **名称**: `IOS_PROVISION_PROFILE_BASE64`
- **值**: 打开 `provision_base64.txt`，复制全部内容

### Secret 4
- **名称**: `KEYCHAIN_PASSWORD`
- **值**: `actions_temp_password`

---

## 第3步：获取Team ID

### 方法1：从配置文件获取

```powershell
# 在PowerShell中执行
$content = Get-Content "E:\FengShuiLuopan_ios\FengShuiLuopan_Dev.mobileprovision" -Raw
if ($content -match '<key>TeamIdentifier</key>\s*<array>\s*<string>([^<]+)</string>') {
    Write-Host "Team ID: $($matches[1])"
} else {
    Write-Host "未找到Team ID，请手动查看配置文件"
}
```

### 方法2：从证书获取

在Mac上执行：
```bash
security find-identity -v -p codesigning
```

---

## 第4步：更新ExportOptions.plist

打开 `E:\FengShuiLuopan_ios\ExportOptions.plist`

找到这一行：
```xml
<key>teamID</key>
<string>YOUR_TEAM_ID</string>
```

将 `YOUR_TEAM_ID` 替换为第3步获取的Team ID。

保存文件并提交：
```bash
git add ExportOptions.plist
git commit -m "ci: 更新Team ID"
git push
```

---

## 第5步：验证配置

推送代码后，访问：
https://github.com/ChimerAI-SZ/FengShuiLuopan_ios/actions

查看 "iOS Build with Signing" workflow的运行状态。

---

## ⚠️ 重要提示

### 当前限制

由于项目还没有完整的Xcode项目文件（.xcodeproj 或 .xcworkspace），GitHub Actions构建会失败。

### 解决方法

需要在本地Mac上：

1. 打开Xcode
2. 创建或配置项目
3. 提交项目文件到Git：
   ```bash
   git add FengShuiLuopan.xcodeproj
   git add FengShuiLuopan.xcworkspace  # 如果使用CocoaPods
   git commit -m "feat: 添加Xcode项目文件"
   git push
   ```

---

## 📝 检查清单

- [ ] 执行 generate_base64.ps1
- [ ] 添加4个GitHub Secrets
- [ ] 获取Team ID
- [ ] 更新ExportOptions.plist
- [ ] 提交ExportOptions.plist
- [ ] 在Mac上创建Xcode项目（待完成）
- [ ] 提交Xcode项目文件（待完成）
- [ ] 验证GitHub Actions构建

---

## 🎯 当前状态

✅ **已完成**：
- Base64编码脚本
- GitHub Actions workflow
- ExportOptions.plist模板
- 完整文档

⏳ **待完成**：
- 配置GitHub Secrets（需要你手动操作）
- 更新Team ID（需要你手动操作）
- 创建Xcode项目（需要在Mac上操作）

---

详细说明见：[IOS_SIGNING_GUIDE.md](IOS_SIGNING_GUIDE.md)
