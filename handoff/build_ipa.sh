#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# 同事填写区：填入你的 Apple 开发者信息
# ============================================================
DEVELOPMENT_TEAM="${DEVELOPMENT_TEAM:-XXXXXXXXXX}"   # 你的 Team ID（Apple Developer 后台可查）
# ============================================================

if [[ "${DEVELOPMENT_TEAM}" == "XXXXXXXXXX" ]]; then
  echo "错误：请先在 handoff/build_ipa.sh 中填写 DEVELOPMENT_TEAM。"
  exit 1
fi

for cmd in xcodegen pod xcodebuild; do
  if ! command -v "${cmd}" >/dev/null 2>&1; then
    echo "错误：未找到命令 ${cmd}，请先安装后再运行脚本。"
    exit 1
  fi
done

WORKSPACE="FengShuiLuopan.xcworkspace"
SCHEME="FengShuiLuopan"
CONFIGURATION="Release"
BUILD_DIR="${PWD}/build"
ARCHIVE_PATH="${BUILD_DIR}/FengShuiLuopan-AppStore.xcarchive"
EXPORT_PATH="${BUILD_DIR}/export"
EXPORT_OPTIONS_TEMPLATE="${PWD}/handoff/ExportOptions_AppStore.plist"
EXPORT_OPTIONS_PLIST="${BUILD_DIR}/ExportOptions_AppStore.generated.plist"

mkdir -p "${BUILD_DIR}" "${EXPORT_PATH}"
cp "${EXPORT_OPTIONS_TEMPLATE}" "${EXPORT_OPTIONS_PLIST}"
/usr/bin/sed -i '' "s/TEAM_ID_PLACEHOLDER/${DEVELOPMENT_TEAM}/g" "${EXPORT_OPTIONS_PLIST}"

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
  -allowProvisioningUpdates \
  DEVELOPMENT_TEAM="${DEVELOPMENT_TEAM}" \
  CODE_SIGN_STYLE="Automatic" \
  clean archive

echo "[3/3] 导出 IPA..."
xcodebuild \
  -exportArchive \
  -archivePath "${ARCHIVE_PATH}" \
  -exportPath "${EXPORT_PATH}" \
  -allowProvisioningUpdates \
  -exportOptionsPlist "${EXPORT_OPTIONS_PLIST}"

echo ""
echo "✅ 完成！"
echo "Archive: ${ARCHIVE_PATH}"
echo "IPA 位置: ${EXPORT_PATH}"
echo "导出配置: ${EXPORT_OPTIONS_PLIST}"
echo ""
echo "下一步：用 Xcode Organizer 或 Transporter 上传 IPA 到 TestFlight"
