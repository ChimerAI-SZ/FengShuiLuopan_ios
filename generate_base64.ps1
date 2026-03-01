# iOS证书和配置文件Base64编码脚本
# 在PowerShell中执行此脚本

# 1. 编码证书文件
$certPath = "E:\FengShuiLuopan_ios\FengShuiLuopan_ios.p12"
$certBytes = [System.IO.File]::ReadAllBytes($certPath)
$certBase64 = [System.Convert]::ToBase64String($certBytes)
$certBase64 | Out-File -FilePath "E:\FengShuiLuopan_ios\certificate_base64.txt" -Encoding ASCII
Write-Host "✅ 证书Base64已保存到: E:\FengShuiLuopan_ios\certificate_base64.txt"
Write-Host "证书Base64长度: $($certBase64.Length) 字符"

# 2. 编码配置文件
$provisionPath = "E:\FengShuiLuopan_ios\FengShuiLuopan_Dev.mobileprovision"
$provisionBytes = [System.IO.File]::ReadAllBytes($provisionPath)
$provisionBase64 = [System.Convert]::ToBase64String($provisionBytes)
$provisionBase64 | Out-File -FilePath "E:\FengShuiLuopan_ios\provision_base64.txt" -Encoding ASCII
Write-Host "✅ 配置文件Base64已保存到: E:\FengShuiLuopan_ios\provision_base64.txt"
Write-Host "配置文件Base64长度: $($provisionBase64.Length) 字符"

Write-Host ""
Write-Host "=========================================="
Write-Host "下一步操作："
Write-Host "1. 打开 certificate_base64.txt，复制全部内容"
Write-Host "2. 打开 provision_base64.txt，复制全部内容"
Write-Host "3. 在GitHub仓库中添加这些内容作为Secrets"
Write-Host "=========================================="
