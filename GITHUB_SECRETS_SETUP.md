# GitHub Secrets 配置指南

> 完成 Team ID 提取和 Base64 编码后，需要在 GitHub 上配置 4 个 Secrets

---

## 📋 准备工作

确认以下文件已生成：
- ✅ `certificate_base64.txt` (4116 字符)
- ✅ `provision_base64.txt` (16252 字符)
- ✅ Team ID 已更新到 `ExportOptions.plist`: **66JTX3GW7T**

---

## 🔐 配置步骤

### 1. 打开 GitHub Secrets 设置页面

访问以下 URL（或按照下面的步骤操作）：

```
https://github.com/ChimerAI-SZ/FengShuiLuopan_ios/settings/secrets/actions
```

**或者手动导航：**
1. 打开 https://github.com/ChimerAI-SZ/FengShuiLuopan_ios
2. 点击 **Settings** 标签
3. 左侧菜单选择 **Secrets and variables** → **Actions**

---

### 2. 添加 4 个 Repository Secrets

点击 **New repository secret** 按钮，依次添加以下 4 个 Secrets：

#### Secret 1: IOS_CERTIFICATE_BASE64

- **Name**: `IOS_CERTIFICATE_BASE64`
- **Value**: 打开 `certificate_base64.txt`，复制全部内容（4116 字符）
- 点击 **Add secret**

```
提示：确保复制时没有多余的空格或换行符
```

---

#### Secret 2: IOS_CERTIFICATE_PASSWORD

- **Name**: `IOS_CERTIFICATE_PASSWORD`
- **Value**: `Hp15099837787!`
- 点击 **Add secret**

```
注意：这是证书的密码，请确保输入正确
```

---

#### Secret 3: IOS_PROVISION_PROFILE_BASE64

- **Name**: `IOS_PROVISION_PROFILE_BASE64`
- **Value**: 打开 `provision_base64.txt`，复制全部内容（16252 字符）
- 点击 **Add secret**

```
提示：这个文件比较大，确保完整复制
```

---

#### Secret 4: KEYCHAIN_PASSWORD

- **Name**: `KEYCHAIN_PASSWORD`
- **Value**: 任意强密码（建议使用 `Actions@2024!`）
- 点击 **Add secret**

```
说明：这是 GitHub Actions 临时 Keychain 的密码，可以自定义
```

---

## ✅ 验证配置

配置完成后，你应该看到 4 个 Secrets：

```
✓ IOS_CERTIFICATE_BASE64
✓ IOS_CERTIFICATE_PASSWORD
✓ IOS_PROVISION_PROFILE_BASE64
✓ KEYCHAIN_PASSWORD
```

---

## 🚀 触发构建

配置完成后，有两种方式触发构建：

### 方式1: 推送代码（自动触发）

```bash
# 任何推送到 main 分支的代码都会触发构建
git push
```

### 方式2: 手动触发

1. 进入 GitHub 仓库的 **Actions** 标签页
2. 选择 **iOS Build with Signing** workflow
3. 点击 **Run workflow** 按钮
4. 选择 `main` 分支
5. 点击 **Run workflow**

---

## 📦 查看构建结果

1. 进入 **Actions** 标签页
2. 点击最新的 workflow 运行
3. 等待构建完成（约 5-10 分钟）
4. 构建成功后，在页面底部的 **Artifacts** 区域可以下载：
   - `FengShuiLuopan.ipa` - 签名后的 IPA 文件
   - `FengShuiLuopan.app.dSYM.zip` - 调试符号文件

---

## 🔍 故障排查

### 问题1: "Certificate import failed"

**可能原因**:
- `IOS_CERTIFICATE_BASE64` 内容不完整
- `IOS_CERTIFICATE_PASSWORD` 密码错误

**解决方案**:
1. 重新运行 `python generate_base64.py`
2. 确认 `certificate_base64.txt` 内容完整（4116 字符）
3. 确认密码为 `Hp15099837787!`

---

### 问题2: "Provisioning profile not found"

**可能原因**:
- `IOS_PROVISION_PROFILE_BASE64` 内容不完整
- 配置文件与 Bundle ID 不匹配

**解决方案**:
1. 重新运行 `python generate_base64.py`
2. 确认 `provision_base64.txt` 内容完整（16252 字符）
3. 确认 Bundle ID 为 `com.fengshuizohar.ios.dev`

---

### 问题3: "Code signing failed"

**可能原因**:
- Team ID 不正确
- 配置文件已过期

**解决方案**:
1. 确认 Team ID 为 `66JTX3GW7T`
2. 检查配置文件有效期（到期日期：2026-03-08）
3. 如果配置文件过期，需要重新生成

---

### 问题4: "Xcode project not found"

**可能原因**:
- GitHub Actions workflow 中的项目创建步骤失败

**解决方案**:
1. 查看 Actions 日志中的 "Create Xcode Project Structure" 步骤
2. 确认 `project.pbxproj` 和 `xcscheme` 文件创建成功

---

## 📊 构建流程说明

GitHub Actions 会自动执行以下步骤：

1. ✅ **Checkout code** - 拉取代码
2. ✅ **Setup Xcode** - 配置 Xcode 环境
3. ✅ **Create Xcode Project** - 自动创建项目结构
4. ✅ **Install Certificate** - 导入开发证书
5. ✅ **Install Provisioning Profile** - 安装配置文件
6. ✅ **Build Archive** - 构建并归档
7. ✅ **Export IPA** - 导出签名的 IPA
8. ✅ **Upload Artifacts** - 上传构建产物

---

## 🎯 下一步

配置完成并构建成功后：

1. 下载 IPA 文件
2. 使用 Xcode 或 Apple Configurator 安装到测试设备
3. 验证应用功能

---

## 📚 相关文档

- [COMPLETE_SETUP_GUIDE.md](COMPLETE_SETUP_GUIDE.md) - 完整配置指南
- [SETUP_QUICK_REF.md](SETUP_QUICK_REF.md) - 快速参考卡
- [IOS_SIGNING_GUIDE.md](IOS_SIGNING_GUIDE.md) - iOS 签名详细指南

---

## 💡 提示

- Secrets 配置后不可查看，只能更新或删除
- 建议保存 `certificate_base64.txt` 和 `provision_base64.txt` 到安全位置
- 配置文件有效期为 7 天（到期日期：2026-03-08）
- 证书有效期为 1 年

---

**配置完成后，每次推送代码到 main 分支都会自动触发构建！** 🎉
