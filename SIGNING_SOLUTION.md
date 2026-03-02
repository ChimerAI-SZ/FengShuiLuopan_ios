# iOS 构建问题解决方案 - 三步走策略

## 📋 概述

我们创建了三个独立的 GitHub Actions workflow，按顺序执行以诊断和解决签名问题：

1. **方案B**: 验证代码编译（不涉及签名）
2. **方案C**: 诊断签名配置
3. **方案A**: 使用 Fastlane 构建

---

## 🔍 方案B: 验证代码编译

**文件**: `.github/workflows/ios-build-test.yml`

**目的**: 验证代码本身没有问题，能够成功编译

**特点**:
- ✅ 使用 iOS Simulator 构建
- ✅ 完全禁用代码签名
- ✅ 只验证代码编译，不生成 IPA
- ✅ 快速反馈（约 5-10 分钟）

**如何运行**:
```bash
# 提交代码会自动触发
git add .github/workflows/ios-build-test.yml
git commit -m "test: 添加无签名构建测试"
git push
```

**预期结果**:
- ✅ 如果成功：代码没问题，问题在签名配置
- ❌ 如果失败：代码本身有编译错误，需要先修复

---

## 🔬 方案C: 诊断签名配置

**文件**: `.github/workflows/ios-signing-diagnostic.yml`

**目的**: 详细诊断签名配置，找出问题根源

**诊断内容**:
1. 列出所有证书
2. 列出所有 Provisioning Profiles
3. 解析 Provisioning Profile 内容（Team ID, Bundle ID, UUID）
4. 检查生成的项目配置
5. 列出 Xcode 可见的 Provisioning Profiles
6. 验证 Bundle ID 匹配
7. 尝试构建并捕获详细错误

**如何运行**:
```bash
# 手动触发（workflow_dispatch）
git add .github/workflows/ios-signing-diagnostic.yml
git commit -m "test: 添加签名诊断工具"
git push

# 然后在 GitHub Actions 页面手动触发
```

**预期输出**:
- 证书信息
- Provisioning Profile 详细内容
- Bundle ID 和 Team ID 匹配情况
- 详细的构建错误信息

---

## 🚀 方案A: 使用 Fastlane

**文件**:
- `.github/workflows/ios-build-fastlane.yml`
- `fastlane/Fastfile`

**目的**: 使用行业标准工具 Fastlane 管理签名和构建

**优势**:
- ✅ 标准化的签名流程
- ✅ 更好的错误提示
- ✅ 自动处理常见签名问题
- ✅ 易于维护和调试

**Fastlane 配置**:
```ruby
# fastlane/Fastfile
build_app(
  workspace: "FengShuiLuopan.xcworkspace",
  scheme: "FengShuiLuopan",
  export_method: "development",
  codesigning_identity: "Apple Development",
  export_options: {
    method: "development",
    teamID: "66JTX3GW7T",
    provisioningProfiles: {
      "com.fengshuizohar.ios.dev" => "FengShuiLuopan Dev"
    }
  }
)
```

**如何运行**:
```bash
# 手动触发（workflow_dispatch）
git add .github/workflows/ios-build-fastlane.yml fastlane/Fastfile
git commit -m "feat: 添加 Fastlane 构建支持"
git push

# 然后在 GitHub Actions 页面手动触发
```

---

## 📝 执行顺序

### 第一步: 方案B（立即执行）

```bash
git add .github/workflows/ios-build-test.yml
git commit -m "test: 添加无签名构建测试"
git push
```

**等待结果**:
- ✅ 成功 → 进入第二步
- ❌ 失败 → 修复代码编译错误

### 第二步: 方案C（诊断）

```bash
git add .github/workflows/ios-signing-diagnostic.yml
git commit -m "test: 添加签名诊断工具"
git push
```

然后在 GitHub Actions 页面手动触发 "iOS Signing Diagnostic" workflow

**分析输出**:
- 检查 Provisioning Profile 的 Bundle ID 是否匹配
- 检查 Team ID 是否正确
- 查看详细的签名错误信息

### 第三步: 方案A（Fastlane）

根据方案C的诊断结果，可能需要调整配置，然后：

```bash
git add .github/workflows/ios-build-fastlane.yml fastlane/Fastfile
git commit -m "feat: 添加 Fastlane 构建支持"
git push
```

在 GitHub Actions 页面手动触发 "iOS Build with Fastlane" workflow

---

## 🎯 预期结果

### 方案B 成功后
- ✅ 确认代码可以编译
- ✅ 问题确定在签名配置
- ➡️ 继续方案C

### 方案C 完成后
- 📊 获得详细的签名配置信息
- 🔍 找出 Bundle ID / Team ID / Profile 不匹配的具体原因
- 📝 根据诊断结果调整配置
- ➡️ 继续方案A

### 方案A 成功后
- ✅ IPA 构建成功
- ✅ 可以下载并安装到设备
- 🎉 问题解决

---

## 🔧 可能需要的调整

根据方案C的诊断结果，可能需要调整：

### 1. Bundle ID 不匹配
修改 `project.yml`:
```yaml
PRODUCT_BUNDLE_IDENTIFIER: com.fengshuizohar.ios.dev  # 确保与 Profile 一致
```

### 2. Team ID 不正确
修改所有相关文件中的 Team ID

### 3. Provisioning Profile 名称不匹配
修改 `fastlane/Fastfile`:
```ruby
provisioningProfiles: {
  "com.fengshuizohar.ios.dev" => "实际的 Profile 名称"
}
```

### 4. 证书类型不匹配
修改 `ExportOptions.plist` 和 Fastfile 中的 `method`:
- `development` - 开发证书
- `ad-hoc` - Ad Hoc 分发
- `enterprise` - 企业证书

---

## 📊 当前状态

- ✅ XcodeGen 集成成功
- ✅ CocoaPods 集成成功
- ✅ 证书和 Profile 安装成功
- ❌ 签名构建失败（17+ 次）

**问题**: xcodebuild 无法找到匹配的 provisioning profile

**解决策略**: 三步走
1. 验证代码编译 ✅
2. 诊断签名配置 🔍
3. 使用 Fastlane 构建 🚀

---

## 🚦 下一步行动

### 立即执行

```bash
# 1. 提交方案B（自动触发）
git add .github/workflows/ios-build-test.yml
git commit -m "test: 添加无签名构建测试"
git push

# 2. 提交方案C（手动触发）
git add .github/workflows/ios-signing-diagnostic.yml
git commit -m "test: 添加签名诊断工具"
git push

# 3. 提交方案A（手动触发）
git add .github/workflows/ios-build-fastlane.yml fastlane/Fastfile
git commit -m "feat: 添加 Fastlane 构建支持"
git push
```

### 等待和分析

1. 查看方案B的构建结果
2. 手动触发方案C，分析诊断输出
3. 根据诊断结果调整配置
4. 手动触发方案A，验证 Fastlane 构建

---

## 📚 参考资料

- [Fastlane 官方文档](https://docs.fastlane.tools/)
- [Xcode Build Settings Reference](https://developer.apple.com/documentation/xcode/build-settings-reference)
- [Code Signing Guide](https://developer.apple.com/support/code-signing/)

---

**创建时间**: 2026-03-02
**状态**: 准备执行
