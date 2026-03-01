#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
update_team_id.py
自动提取 Team ID 并更新 ExportOptions.plist
"""

import re
import sys
import io
from pathlib import Path

# 修复 Windows 控制台编码问题
if sys.platform == 'win32':
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
    sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding='utf-8')

def main():
    # 文件路径
    provision_path = Path("E:/FengShuiLuopan_ios/FengShuiLuopan_Dev.mobileprovision")
    export_options_path = Path("E:/FengShuiLuopan_ios/ExportOptions.plist")

    print("=== iOS Team ID 自动更新工具 ===\n")

    # 1. 检查文件是否存在
    if not provision_path.exists():
        print("❌ 错误: 找不到 provisioning profile")
        sys.exit(1)

    if not export_options_path.exists():
        print("❌ 错误: 找不到 ExportOptions.plist")
        sys.exit(1)

    # 2. 提取 Team ID
    print("[1/3] 正在提取 Team ID...")

    try:
        with open(provision_path, 'rb') as f:
            content = f.read().decode('utf-8', errors='ignore')

        # 提取 XML 部分
        xml_match = re.search(r'<\?xml.*?</plist>', content, re.DOTALL)
        if not xml_match:
            print("      ❌ 无法解析 provisioning profile")
            sys.exit(1)

        xml_content = xml_match.group(0)

        # 提取 TeamIdentifier
        team_match = re.search(r'<key>TeamIdentifier</key>\s*<array>\s*<string>([^<]+)</string>', xml_content)
        if not team_match:
            print("      ❌ 无法提取 Team ID")
            sys.exit(1)

        team_id = team_match.group(1)
        print(f"      ✅ Team ID: {team_id}")

    except Exception as e:
        print(f"      ❌ 读取文件失败: {e}")
        sys.exit(1)

    # 3. 更新 ExportOptions.plist
    print("[2/3] 正在更新 ExportOptions.plist...")

    try:
        with open(export_options_path, 'r', encoding='utf-8') as f:
            export_content = f.read()

        if '<string>YOUR_TEAM_ID</string>' in export_content:
            new_content = export_content.replace('<string>YOUR_TEAM_ID</string>', f'<string>{team_id}</string>')

            with open(export_options_path, 'w', encoding='utf-8', newline='\n') as f:
                f.write(new_content)

            print("      ✅ 已更新 Team ID")
        else:
            print("      ⚠️  Team ID 可能已经更新过了")

    except Exception as e:
        print(f"      ❌ 更新文件失败: {e}")
        sys.exit(1)

    # 4. 验证更新
    print("[3/3] 验证更新结果...")

    try:
        with open(export_options_path, 'r', encoding='utf-8') as f:
            verify_content = f.read()

        if f'<string>{team_id}</string>' in verify_content:
            print("      ✅ 验证成功!")
        else:
            print("      ❌ 验证失败")
            sys.exit(1)

    except Exception as e:
        print(f"      ❌ 验证失败: {e}")
        sys.exit(1)

    # 完成
    print("\n=== 更新完成 ===")
    print(f"Team ID: {team_id}\n")
    print("下一步: 提交更改到 GitHub")
    print("  git add ExportOptions.plist")
    print("  git commit -m 'chore: 更新 Team ID'")
    print("  git push")

if __name__ == '__main__':
    main()
