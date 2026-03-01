#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
generate_base64.py
生成证书和配置文件的 Base64 编码
"""

import base64
import sys
import io
from pathlib import Path

# 修复 Windows 控制台编码问题
if sys.platform == 'win32':
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
    sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding='utf-8')

def main():
    # 文件路径
    cert_path = Path("E:/FengShuiLuopan_ios/FengShuiLuopan_ios.p12")
    provision_path = Path("E:/FengShuiLuopan_ios/FengShuiLuopan_Dev.mobileprovision")

    print("=== iOS 签名文件 Base64 编码工具 ===\n")

    # 1. 检查文件是否存在
    if not cert_path.exists():
        print(f"❌ 错误: 找不到证书文件 {cert_path}")
        sys.exit(1)

    if not provision_path.exists():
        print(f"❌ 错误: 找不到配置文件 {provision_path}")
        sys.exit(1)

    # 2. 编码证书
    print("[1/2] 正在编码证书...")
    try:
        with open(cert_path, 'rb') as f:
            cert_bytes = f.read()
        cert_base64 = base64.b64encode(cert_bytes).decode('ascii')

        with open('certificate_base64.txt', 'w', encoding='ascii') as f:
            f.write(cert_base64)

        print(f"      ✅ 证书编码完成 ({len(cert_base64)} 字符)")
    except Exception as e:
        print(f"      ❌ 证书编码失败: {e}")
        sys.exit(1)

    # 3. 编码配置文件
    print("[2/2] 正在编码配置文件...")
    try:
        with open(provision_path, 'rb') as f:
            provision_bytes = f.read()
        provision_base64 = base64.b64encode(provision_bytes).decode('ascii')

        with open('provision_base64.txt', 'w', encoding='ascii') as f:
            f.write(provision_base64)

        print(f"      ✅ 配置文件编码完成 ({len(provision_base64)} 字符)")
    except Exception as e:
        print(f"      ❌ 配置文件编码失败: {e}")
        sys.exit(1)

    # 完成
    print("\n=== 编码完成 ===")
    print("已生成文件:")
    print("  - certificate_base64.txt")
    print("  - provision_base64.txt\n")
    print("下一步: 配置 GitHub Secrets")
    print("  1. 进入 GitHub 仓库 → Settings → Secrets and variables → Actions")
    print("  2. 添加以下 4 个 Secrets:")
    print("     - IOS_CERTIFICATE_BASE64 (来自 certificate_base64.txt)")
    print("     - IOS_CERTIFICATE_PASSWORD (Hp15099837787!)")
    print("     - IOS_PROVISION_PROFILE_BASE64 (来自 provision_base64.txt)")
    print("     - KEYCHAIN_PASSWORD (任意强密码，如 Actions@2024!)")

if __name__ == '__main__':
    main()
