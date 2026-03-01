# GitHub Secrets 配置指南

## 需要添加的Secrets

在GitHub仓库页面，进入 **Settings** → **Secrets and variables** → **Actions** → **New repository secret**

添加以下4个Secrets：

### 1. IOS_CERTIFICATE_BASE64
- **名称**: `IOS_CERTIFICATE_BASE64`
- **值**: 打开 `certificate_base64.txt` 文件，复制全部内容粘贴到这里
- **说明**: iOS开发证书的Base64编码

### 2. IOS_CERTIFICATE_PASSWORD
- **名称**: `IOS_CERTIFICATE_PASSWORD`
- **值**: `Hp15099837787!`
- **说明**: 证书密码

### 3. IOS_PROVISION_PROFILE_BASE64
- **名称**: `IOS_PROVISION_PROFILE_BASE64`
- **值**: 打开 `provision_base64.txt` 文件，复制全部内容粘贴到这里
- **说明**: iOS配置文件的Base64编码

### 4. KEYCHAIN_PASSWORD
- **名称**: `KEYCHAIN_PASSWORD`
- **值**: `actions_temp_password`（可以是任意密码，用于临时keychain）
- **说明**: GitHub Actions临时keychain密码

## 操作步骤

1. **生成Base64编码**
   ```powershell
   # 在PowerShell中执行
   .\generate_base64.ps1
   ```

2. **添加Secrets到GitHub**
   - 访问: https://github.com/ChimerAI-SZ/FengShuiLuopan_ios/settings/secrets/actions
   - 点击 "New repository secret"
   - 依次添加上述4个Secrets

3. **验证Secrets**
   - 确保所有4个Secrets都已添加
   - 名称必须完全匹配（区分大小写）
   - Base64内容不要有多余的空格或换行

## 注意事项

⚠️ **安全提示**:
- Secrets一旦添加，无法再查看其值
- 如果需要修改，只能删除后重新添加
- 不要在代码或日志中打印Secrets的值

✅ **验证方法**:
- 添加完成后，推送代码触发GitHub Actions
- 查看Actions日志，确认证书导入成功
- 如果失败，检查Base64编码是否正确
