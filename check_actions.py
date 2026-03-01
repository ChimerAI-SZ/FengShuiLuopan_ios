#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
check_actions.py
检查 GitHub Actions 运行状态
"""

import sys
import io
import json
import urllib.request
import urllib.error
from datetime import datetime

# 修复 Windows 控制台编码问题
if sys.platform == 'win32':
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
    sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding='utf-8')

def main():
    # GitHub API 配置
    owner = "ChimerAI-SZ"
    repo = "FengShuiLuopan_ios"
    api_url = f"https://api.github.com/repos/{owner}/{repo}/actions/runs"

    print("=== GitHub Actions 状态检查 ===\n")

    try:
        # 发送 API 请求
        req = urllib.request.Request(api_url)
        req.add_header('Accept', 'application/vnd.github.v3+json')

        with urllib.request.urlopen(req, timeout=10) as response:
            data = json.loads(response.read().decode('utf-8'))

        runs = data.get('workflow_runs', [])

        if not runs:
            print("❌ 没有找到任何 workflow 运行记录")
            return

        print(f"最近 {min(5, len(runs))} 次运行:\n")

        for i, run in enumerate(runs[:5], 1):
            workflow_name = run.get('name', 'Unknown')
            status = run.get('status', 'unknown')
            conclusion = run.get('conclusion', 'N/A')
            created_at = run.get('created_at', '')
            html_url = run.get('html_url', '')
            run_number = run.get('run_number', 0)

            # 格式化时间
            if created_at:
                dt = datetime.fromisoformat(created_at.replace('Z', '+00:00'))
                time_str = dt.strftime('%Y-%m-%d %H:%M:%S')
            else:
                time_str = 'Unknown'

            # 状态图标
            if status == 'completed':
                if conclusion == 'success':
                    status_icon = '✅'
                    status_text = '成功'
                elif conclusion == 'failure':
                    status_icon = '❌'
                    status_text = '失败'
                elif conclusion == 'cancelled':
                    status_icon = '🚫'
                    status_text = '取消'
                else:
                    status_icon = '⚠️'
                    status_text = conclusion or 'Unknown'
            elif status == 'in_progress':
                status_icon = '🔄'
                status_text = '运行中'
            elif status == 'queued':
                status_icon = '⏳'
                status_text = '排队中'
            else:
                status_icon = '❓'
                status_text = status

            print(f"{i}. {status_icon} #{run_number} - {workflow_name}")
            print(f"   状态: {status_text}")
            print(f"   时间: {time_str}")
            print(f"   链接: {html_url}")
            print()

        # 检查最新运行
        latest_run = runs[0]
        latest_status = latest_run.get('status')
        latest_conclusion = latest_run.get('conclusion')

        print("=" * 50)
        print("\n最新运行状态:")

        if latest_status == 'completed':
            if latest_conclusion == 'success':
                print("✅ 构建成功！")
                print("\n下一步:")
                print("1. 访问 Actions 页面下载 IPA 文件")
                print(f"2. {latest_run.get('html_url')}")
            elif latest_conclusion == 'failure':
                print("❌ 构建失败")
                print("\n查看详细日志:")
                print(f"{latest_run.get('html_url')}")
            else:
                print(f"⚠️ 构建完成，但状态为: {latest_conclusion}")
        elif latest_status == 'in_progress':
            print("🔄 构建正在进行中...")
            print(f"查看进度: {latest_run.get('html_url')}")
        elif latest_status == 'queued':
            print("⏳ 构建已排队，等待开始...")
        else:
            print(f"❓ 未知状态: {latest_status}")

    except urllib.error.HTTPError as e:
        print(f"❌ HTTP 错误: {e.code} - {e.reason}")
        if e.code == 404:
            print("提示: 仓库不存在或无权访问")
        elif e.code == 403:
            print("提示: API 速率限制，请稍后再试")
    except urllib.error.URLError as e:
        print(f"❌ 网络错误: {e.reason}")
    except Exception as e:
        print(f"❌ 错误: {e}")

if __name__ == '__main__':
    main()
