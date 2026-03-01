# update_team_id.ps1
# 自动提取 Team ID 并更新 ExportOptions.plist

$provisionPath = "E:\FengShuiLuopan_ios\FengShuiLuopan_Dev.mobileprovision"
$exportOptionsPath = "E:\FengShuiLuopan_ios\ExportOptions.plist"

Write-Host "=== iOS Team ID 自动更新工具 ===" -ForegroundColor Cyan
Write-Host ""

# 1. 检查文件是否存在
if (-not (Test-Path $provisionPath)) {
    Write-Host "错误: 找不到 provisioning profile" -ForegroundColor Red
    exit 1
}

if (-not (Test-Path $exportOptionsPath)) {
    Write-Host "错误: 找不到 ExportOptions.plist" -ForegroundColor Red
    exit 1
}

# 2. 提取 Team ID
Write-Host "[1/3] 正在提取 Team ID..." -ForegroundColor Yellow
$content = Get-Content $provisionPath -Raw

if ($content -match '(?s)<\?xml.*?</plist>') {
    $xmlContent = $matches[0]

    if ($xmlContent -match '<key>TeamIdentifier</key>\s*<array>\s*<string>([^<]+)</string>') {
        $teamId = $matches[1]
        Write-Host "      ✓ Team ID: $teamId" -ForegroundColor Green
    } else {
        Write-Host "      ✗ 无法提取 Team ID" -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "      ✗ 无法解析 provisioning profile" -ForegroundColor Red
    exit 1
}

# 3. 更新 ExportOptions.plist
Write-Host "[2/3] 正在更新 ExportOptions.plist..." -ForegroundColor Yellow
$exportContent = Get-Content $exportOptionsPath -Raw

if ($exportContent -match '<string>YOUR_TEAM_ID</string>') {
    $newContent = $exportContent -replace '<string>YOUR_TEAM_ID</string>', "<string>$teamId</string>"
    $newContent | Out-File -FilePath $exportOptionsPath -Encoding UTF8 -NoNewline
    Write-Host "      ✓ 已更新 Team ID" -ForegroundColor Green
} else {
    Write-Host "      ! Team ID 可能已经更新过了" -ForegroundColor Yellow
}

# 4. 验证更新
Write-Host "[3/3] 验证更新结果..." -ForegroundColor Yellow
$verifyContent = Get-Content $exportOptionsPath -Raw
if ($verifyContent -match "<string>$teamId</string>") {
    Write-Host "      ✓ 验证成功!" -ForegroundColor Green
} else {
    Write-Host "      ✗ 验证失败" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "=== 更新完成 ===" -ForegroundColor Green
Write-Host "Team ID: $teamId" -ForegroundColor Yellow
Write-Host ""
Write-Host "下一步: 提交更改到 GitHub" -ForegroundColor Cyan
Write-Host "  git add ExportOptions.plist" -ForegroundColor White
Write-Host "  git commit -m 'chore: 更新 Team ID'" -ForegroundColor White
Write-Host "  git push" -ForegroundColor White
