#!/usr/bin/env python3
"""
下载最新的 Fastlane 构建日志
"""

import requests
import sys
import zipfile
import io

def download_fastlane_log():
    """下载 fastlane-log artifact"""

    # GitHub API
    repo = "ChimerAI-SZ/FengShuiLuopan_ios"
    run_id = "22560656310"

    # 获取 artifacts
    url = f"https://api.github.com/repos/{repo}/actions/runs/{run_id}/artifacts"

    print(f"📥 获取 artifacts 列表...")
    print(f"URL: {url}")

    response = requests.get(url)

    if response.status_code != 200:
        print(f"❌ 请求失败: {response.status_code}")
        print(response.text)
        return

    data = response.json()
    artifacts = data.get("artifacts", [])

    print(f"\n找到 {len(artifacts)} 个 artifacts:")
    for artifact in artifacts:
        print(f"  - {artifact['name']} ({artifact['size_in_bytes']} bytes)")

    # 查找 fastlane-log
    fastlane_log = None
    for artifact in artifacts:
        if artifact['name'] == 'fastlane-log':
            fastlane_log = artifact
            break

    if not fastlane_log:
        print("\n❌ 未找到 fastlane-log artifact")
        return

    print(f"\n📦 下载 fastlane-log...")
    download_url = fastlane_log['archive_download_url']
    print(f"下载 URL: {download_url}")

    # 注意：下载 artifact 需要认证
    print("\n⚠️  下载 artifact 需要 GitHub token")
    print("请手动下载:")
    print(f"1. 访问: https://github.com/{repo}/actions/runs/{run_id}")
    print(f"2. 点击 'fastlane-log' artifact 下载")
    print(f"3. 解压后查看 fastlane.log 文件")

if __name__ == "__main__":
    download_fastlane_log()
