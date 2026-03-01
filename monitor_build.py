#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
monitor_build.py
监控 GitHub Actions 构建进度
"""

import sys
import io
import json
import urllib.request
import urllib.error
import time
from datetime import datetime

# 修复 Windows 控制台编码问题
if sys.platform == 'win32':
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
    sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding='utf-8')

def get_latest_run():
    """获取最新的 workflow 运行"""
    owner = "ChimerAI-SZ"
    repo = "FengShuiLuopan_ios"
    api_url = f"https://api.github.com/repos/{owner}/{repo}/actions/runs"

    req = urllib.request.Request(api_url)
    req.add_header('Accept', 'application/vnd.github.v3+json')

    with urllib.request.urlopen(req, timeout=10) as response:
        data = json.loads(response.read().decode('utf-8'))

    runs = data.get('workflow_runs', [])
    if not runs:
        return None

    # 找到最新的 "iOS Build with Signing" workflow
    for run in runs:
        if run.get('name') == 'iOS Build with Signing':
            return run

    return runs[0]

def main():
    print("=== GitHub Actions 构建监控 ===\n")
    print("监控最新的 'iOS Build with Signing' workflow")
    print("按 Ctrl+C 停止监控\n")

    last_status = None
    check_count = 0

    try:
        while True:
            check_count += 1

            try:
                run = get_latest_run()

                if not run:
                    print("❌ 没有找到 workflow 运行")
                    break

                status = run.get('status')
                conclusion = run.get('conclusion')
                run_number = run.get('run_number')
                html_url = run.get('html_url')

                # 只在状态变化时打印
                current_status = f"{status}:{conclusion}"
                if current_status != last_status:
                    timestamp = datetime.now().strftime('%H:%M:%S')

                    if status == 'completed':
                        if conclusion == 'success':
                            print(f"\n[{timestamp}] ✅ 构建成功！ (#{run_number})")
                            print(f"查看结果: {html_url}")
                            print("\n下一步:")
                            print("1. 访问 Actions 页面")
                            print("2. 在页面底部的 Artifacts 区域下载 IPA 文件")
                            break
                        elif conclusion == 'failure':
                            print(f"\n[{timestamp}] ❌ 构建失败 (#{run_number})")
                            print(f"查看日志: {html_url}")
                            break
                        else:
                            print(f"\n[{timestamp}] ⚠️ 构建完成，状态: {conclusion} (#{run_number})")
                            break
                    elif status == 'in_progress':
                        print(f"[{timestamp}] 🔄 构建进行中... (#{run_number}) [检查 {check_count} 次]")
                    elif status == 'queued':
                        print(f"[{timestamp}] ⏳ 构建排队中... (#{run_number})")

                    last_status = current_status

                # 每 30 秒检查一次
                time.sleep(30)

            except urllib.error.HTTPError as e:
                print(f"❌ HTTP 错误: {e.code}")
                if e.code == 403:
                    print("API 速率限制，等待 60 秒...")
                    time.sleep(60)
                else:
                    break
            except urllib.error.URLError as e:
                print(f"❌ 网络错误: {e.reason}")
                time.sleep(30)

    except KeyboardInterrupt:
        print("\n\n⏹️  监控已停止")
        if last_status:
            print(f"最后状态: {last_status}")

if __name__ == '__main__':
    main()
