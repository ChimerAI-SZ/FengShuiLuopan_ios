# extract_team_id.ps1
# 从 .mobileprovision 文件中提取 Team ID

$provisionPath = "E:\FengShuiLuopan_ios\FengShuiLuopan_Dev.mobileprovision"

if (-not (Test-Path $provisionPath)) {
    Write-Host "错误: 找不到文件 $provisionPath" -ForegroundColor Red
    exit 1
}

Write-Host "正在读取 provisioning profile..." -ForegroundColor Cyan

# 读取文件内容
$content = Get-Content $provisionPath -Raw

# 提取 plist XML 部分（在 <?xml 和 </plist> 之间）
if ($content -match '(?s)<\?xml.*?</plist>') {
    $xmlContent = $matches[0]

    # 提取 TeamIdentifier
    if ($xmlContent -match '<key>TeamIdentifier</key>\s*<array>\s*<string>([^<]+)</string>') {
        $teamId = $matches[1]
        Write-Host "`n✓ Team ID 提取成功!" -ForegroundColor Green
        Write-Host "Team ID: $teamId" -ForegroundColor Yellow

        # 保存到文件
        $teamId | Out-File -FilePath "team_id.txt" -Encoding ASCII -NoNewline
        Write-Host "`n已保存到: team_id.txt" -ForegroundColor Green

        # 显示如何使用
        Write-Host "`n下一步操作:" -ForegroundColor Cyan
        Write-Host "1. 打开 ExportOptions.plist" -ForegroundColor White
        Write-Host "2. 将 <string>YOUR_TEAM_ID</string> 替换为 <string>$teamId</string>" -ForegroundColor White

        exit 0
    } else {
        Write-Host "错误: 无法在 XML 中找到 TeamIdentifier" -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "错误: 无法解析 provisioning profile 格式" -ForegroundColor Red
    exit 1
}
