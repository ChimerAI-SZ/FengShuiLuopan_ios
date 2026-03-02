# Bundle ID 匹配问题修复

## 问题诊断

### 根本原因
Provisioning Profile 和项目配置的 Bundle ID 不匹配，导致 Fastlane 构建失败。

### 详细分析
通过检查 `FengShuiLuopan_Dev.mobileprovision` 文件发现：

**Provisioning Profile 配置：**
- Bundle ID: `com.he.FengShuiLuopan`
- Team ID: `66JTX3GW7T`
- Profile Name: `FengShuiLuopan_Dev`
- UUID: `aad6c8cc-b723-4ec4-9f82-5166facffaac`
- 有效期: 2026-03-09（还有 7 天）

**项目原配置（错误）：**
- Bundle ID: `com.fengshuizohar.ios.dev`
- 这与 Provisioning Profile 不匹配！

## 修复内容

### 1. project.yml
```yaml
# 修改前
options:
  bundleIdPrefix: com.fengshuizohar.ios

settings:
  base:
    PRODUCT_BUNDLE_IDENTIFIER: com.fengshuizohar.ios.dev

# 修改后
options:
  bundleIdPrefix: com.he

settings:
  base:
    PRODUCT_BUNDLE_IDENTIFIER: com.he.FengShuiLuopan
```

### 2. fastlane/Fastfile
```ruby
# 修改前
provisioningProfiles: {
  "com.fengshuizohar.ios.dev" => "FengShuiLuopan Dev"
}

# 修改后
provisioningProfiles: {
  "com.he.FengShuiLuopan" => "FengShuiLuopan_Dev"
}
```

### 3. .github/workflows/ios-build-fastlane.yml
添加了签名验证步骤：
- 列出已安装的证书
- 列出已安装的 Provisioning Profiles
- 显示 Profile 详细信息（Name, UUID, TeamID, Bundle ID）
- 捕获完整的 Fastlane 日志并上传为 artifact

## 验证步骤

1. **手动触发 Fastlane 构建**
   - 访问: https://github.com/ChimerAI-SZ/FengShuiLuopan_ios/actions
   - 选择 "iOS Build with Fastlane"
   - 点击 "Run workflow"

2. **检查签名验证输出**
   - 查看 "Verify Signing Setup" 步骤
   - 确认 Bundle ID 匹配

3. **检查构建结果**
   - 如果成功：下载 IPA 和 dSYM artifacts
   - 如果失败：下载 fastlane-log artifact 查看详细错误

## 预期结果

修复后，Fastlane 应该能够：
1. 正确匹配 Provisioning Profile
2. 成功签名应用
3. 导出 IPA 文件
4. 上传 artifacts

## 提交信息

```
Commit: be49876
Message: fix: 修正 Bundle ID 匹配问题
Branch: main
```

## 下一步

请手动触发 Fastlane 构建验证修复是否成功。
