#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
list_artifacts.py
列出 GitHub Actions 构建产物
"""

import sys
import io
import json
import urllib.request
import urllib.error

# 修复 Windows 控制台编码问题
if sys.platform == 'win32':
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
    sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding='utf-8')

def main():
    # GitHub API 配置
    owner = "ChimerAI-SZ"
    repo = "FengShuiLuopan_ios"
    run_id = "22546862098"  # 最新的运行

    print(f"=== GitHub Actions 构建产物 (Run #{run_id}) ===\n")

    try:
        # 获取 artifacts
        artifacts_url = f"https://api.github.com/repos/{owner}/{repo}/actions/runs/{run_id}/artifacts"
        req = urllib.request.Request(artifacts_url)
        req.add_header('Accept', 'application/vnd.github.v3+json')

        with urllib.request.urlopen(req, timeout=10) as response:
            data = json.loads(response.read().decode('utf-8'))

        artifacts = data.get('artifacts', [])

        if not artifacts:
            print("❌ 没有找到任何构建产物")
            print("\n可能原因:")
            print("1. 构建失败，没有生成 IPA")
            print("2. Artifacts 还在上传中")
            return

        print(f"找到 {len(artifacts)} 个构建产物:\n")

        for i, artifact in enumerate(artifacts, 1):
            name = artifact.get('name', 'Unknown')
            size_bytes = artifact.get('size_in_bytes', 0)
            size_mb = size_bytes / (1024 * 1024)
            expired = artifact.get('expired', False)
            download_url = artifact.get('archive_download_url', '')

            print(f"{i}. 📦 {name}")
            print(f"   大小: {size_mb:.2f} MB")
            print(f"   状态: {'已过期' if expired else '可下载'}")
            print(f"   下载: {download_url}")
            print()

        print("=" * 60)
        print("\n下载方法:")
        print("\n方法1: 通过浏览器下载")
        print(f"访问: https://github.com/{owner}/{repo}/actions/runs/{run_id}")
        print("在页面底部的 Artifacts 区域点击下载")

        print("\n方法2: 使用 GitHub CLI (如果已安装)")
        for artifact in artifacts:
            name = artifact.get('name', 'Unknown')
            print(f"gh run download {run_id} -n {name}")

        print("\n⚠️  注意: Artifacts 有效期为 90 天")

    except urllib.error.HTTPError as e:
        print(f"❌ HTTP 错误: {e.code} - {e.reason}")
    except urllib.error.URLError as e:
        print(f"❌ 网络错误: {e.reason}")
    except Exception as e:
        print(f"❌ 错误: {e}")

if __name__ == '__main__':
    main()
