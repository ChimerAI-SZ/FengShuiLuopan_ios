#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# 同事填写区：填入你的 Apple 开发者信息
# ============================================================
DEVELOPMENT_TEAM="XXXXXXXXXX"   # 你的 Team ID（Apple Developer 后台可查）
# ============================================================

WORKSPACE="FengShuiLuopan.xcworkspace"
SCHEME="FengShuiLuopan"
CONFIGURATION="Release"
ARCHIVE_PATH="${PWD}/build/FengShuiLuopan-AppStore.xcarchive"
EXPORT_PATH="${PWD}/build/export"
EXPORT_OPTIONS_PLIST="${PWD}/handoff/ExportOptions_AppStore.plist"

# 将 Team ID 写入 ExportOptions（临时替换占位符）
sed -i '' "s/TEAM_ID_PLACEHOLDER/${DEVELOPMENT_TEAM}/g" "${EXPORT_OPTIONS_PLIST}"

echo "[0/3] 生成 Xcode 项目..."
xcodegen generate

echo "[1/3] 安装 CocoaPods 依赖..."
pod install

echo "[2/3] Archive..."
xcodebuild \
  -workspace "${WORKSPACE}" \
  -scheme "${SCHEME}" \
  -configuration "${CONFIGURATION}" \
  -destination 'generic/platform=iOS' \
  -archivePath "${ARCHIVE_PATH}" \
  DEVELOPMENT_TEAM="${DEVELOPMENT_TEAM}" \
  CODE_SIGN_STYLE="Automatic" \
  clean archive

echo "[3/3] 导出 IPA..."
xcodebuild \
  -exportArchive \
  -archivePath "${ARCHIVE_PATH}" \
  -exportPath "${EXPORT_PATH}" \
  -exportOptionsPlist "${EXPORT_OPTIONS_PLIST}"

echo ""
echo "✅ 完成！"
echo "Archive: ${ARCHIVE_PATH}"
echo "IPA 位置: ${EXPORT_PATH}"
echo ""
echo "下一步：用 Xcode Organizer 或 Transporter 上传 IPA 到 TestFlight"
