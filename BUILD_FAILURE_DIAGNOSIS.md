# 构建失败诊断 - 2026-03-02

## 📊 当前状态

### 方案B执行结果
- ✅ XcodeGen 生成项目成功
- ✅ CocoaPods 安装依赖成功
- ❌ **编译失败** (Build Without Signing 步骤)

**Run ID**: 22558115343
**链接**: https://github.com/ChimerAI-SZ/FengShuiLuopan_ios/actions/runs/22558115343

---

## 🔍 可能的原因

### 1. AMap SDK 模拟器支持问题
**症状**: 为模拟器构建时 AMap SDK 可能缺少某些架构

**验证方法**:
- 查看完整构建日志中的链接错误
- 检查是否有 "undefined symbol" 或 "architecture" 相关错误

**解决方案**:
```yaml
# 修改 ios-build-test.yml
# 改为真机架构构建（不运行）
xcodebuild clean build \
  -workspace FengShuiLuopan.xcworkspace \
  -scheme FengShuiLuopan \
  -configuration Debug \
  -sdk iphoneos \  # 改为 iphoneos
  -destination 'generic/platform=iOS' \  # 改为通用iOS平台
  CODE_SIGN_IDENTITY="" \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGNING_ALLOWED=NO
```

### 2. 缺少必需的框架或依赖
**症状**: 编译时找不到某些符号或类型

**验证方法**:
- 查看日志中的 "Undefined symbols" 错误
- 检查是否有 import 失败

**解决方案**:
- 在 project.yml 中添加缺失的系统框架
- 确保 CocoaPods 依赖正确链接

### 3. Swift 版本不兼容
**症状**: 语法错误或 API 不可用

**验证方法**:
- 查看日志中的 Swift 编译错误
- 检查 Xcode 版本和 Swift 版本

**当前配置**:
- Xcode: latest-stable
- Swift: 5.9
- iOS: 16.0+

### 4. Info.plist 配置问题
**症状**: 缺少必需的权限描述或配置

**当前配置**:
```yaml
GENERATE_INFOPLIST_FILE: YES
INFOPLIST_KEY_NSLocationWhenInUseUsageDescription: "需要获取您的位置信息以提供风水罗盘功能"
```

**可能需要添加**:
- AMap SDK 的隐私权限
- 其他必需的 Info.plist 键

### 5. 代码本身的编译错误
**症状**: Swift 语法错误、类型错误等

**需要检查的文件**:
- FengShuiLuopanApp.swift
- MainContentView.swift
- MapView.swift
- GaodeMapController.swift
- 其他 Swift 文件

---

## 🎯 下一步行动

### 立即行动: 查看完整日志

1. **访问 GitHub Actions 页面**:
   https://github.com/ChimerAI-SZ/FengShuiLuopan_ios/actions/runs/22558115343

2. **展开 "Build Without Signing" 步骤**

3. **查找关键错误信息**:
   - 搜索 "error:"
   - 搜索 "Undefined symbols"
   - 搜索 "ld: "
   - 搜索 "fatal error"

4. **记录错误信息**并反馈

### 方案B.1: 改为真机架构构建

如果是模拟器架构问题，修改 workflow:

```bash
# 编辑 .github/workflows/ios-build-test.yml
# 将 -sdk iphonesimulator 改为 -sdk iphoneos
# 将 -destination 改为 'generic/platform=iOS'
```

### 方案B.2: 添加详细日志

在 workflow 中添加更详细的诊断:

```yaml
- name: Build Without Signing
  run: |
    echo "🔨 测试构建（不签名）..."

    # 显示可用的 SDK
    xcodebuild -showsdks

    # 显示构建设置
    xcodebuild -showBuildSettings \
      -workspace FengShuiLuopan.xcworkspace \
      -scheme FengShuiLuopan | head -50

    # 构建（带详细输出）
    xcodebuild clean build \
      -workspace FengShuiLuopan.xcworkspace \
      -scheme FengShuiLuopan \
      -configuration Debug \
      -sdk iphonesimulator \
      -destination 'platform=iOS Simulator,name=iPhone 15,OS=latest' \
      CODE_SIGN_IDENTITY="" \
      CODE_SIGNING_REQUIRED=NO \
      CODE_SIGNING_ALLOWED=NO \
      -verbose 2>&1 | tee build.log

    # 如果失败，显示最后100行
    if [ ${PIPESTATUS[0]} -ne 0 ]; then
      echo "=== 构建失败，最后100行日志 ==="
      tail -100 build.log
      exit 1
    fi
```

### 继续方案C: 签名诊断

即使方案B失败，方案C仍然有价值，因为它会：
- 验证证书和 Provisioning Profile 是否正确安装
- 检查签名配置是否匹配
- 提供详细的签名相关信息

**手动触发方案C**:
1. 访问 GitHub Actions 页面
2. 选择 "iOS Signing Diagnostic" workflow
3. 点击 "Run workflow"

---

## 📝 需要的信息

为了继续诊断，需要从 GitHub Actions 日志中获取:

1. **完整的编译错误信息**
   - 错误类型（链接错误、编译错误、配置错误）
   - 具体的错误消息
   - 失败的文件和行号

2. **构建环境信息**
   - Xcode 版本
   - Swift 版本
   - 可用的 SDK

3. **依赖信息**
   - CocoaPods 安装的具体版本
   - AMap SDK 版本

---

## 🔄 备选方案

如果方案B持续失败，可以考虑:

### 选项1: 简化代码
临时移除 AMap SDK 依赖，使用 Apple MapKit 验证基础代码能否编译

### 选项2: 使用参考 App 的配置
完全复制 fengshui-zohar 的 project.yml 和 Podfile

### 选项3: 云Mac 手动构建
租用云Mac，手动打开 Xcode 查看详细错误

---

## 📚 相关文档

- [SIGNING_SOLUTION.md](SIGNING_SOLUTION.md) - 三步走解决方案总览
- [BUILD_STATUS.md](BUILD_STATUS.md) - 之前的构建状态
- [project.yml](project.yml) - XcodeGen 配置
- [Podfile](Podfile) - CocoaPods 配置

---

**创建时间**: 2026-03-02
**状态**: 等待日志分析
