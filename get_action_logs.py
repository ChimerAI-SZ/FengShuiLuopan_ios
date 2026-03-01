#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
get_action_logs.py
获取 GitHub Actions 运行日志
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
    run_id = "22540689027"  # 最新失败的运行

    print(f"=== 获取 GitHub Actions 日志 (Run #{run_id}) ===\n")

    try:
        # 获取 jobs
        jobs_url = f"https://api.github.com/repos/{owner}/{repo}/actions/runs/{run_id}/jobs"
        req = urllib.request.Request(jobs_url)
        req.add_header('Accept', 'application/vnd.github.v3+json')

        with urllib.request.urlopen(req, timeout=10) as response:
            data = json.loads(response.read().decode('utf-8'))

        jobs = data.get('jobs', [])

        if not jobs:
            print("❌ 没有找到任何 job")
            return

        for job in jobs:
            job_name = job.get('name', 'Unknown')
            status = job.get('status', 'unknown')
            conclusion = job.get('conclusion', 'N/A')

            print(f"Job: {job_name}")
            print(f"状态: {status} / {conclusion}\n")

            # 获取步骤信息
            steps = job.get('steps', [])
            for step in steps:
                step_name = step.get('name', 'Unknown')
                step_status = step.get('status', 'unknown')
                step_conclusion = step.get('conclusion', 'N/A')
                step_number = step.get('number', 0)

                # 状态图标
                if step_conclusion == 'success':
                    icon = '✅'
                elif step_conclusion == 'failure':
                    icon = '❌'
                elif step_conclusion == 'skipped':
                    icon = '⏭️'
                elif step_status == 'in_progress':
                    icon = '🔄'
                else:
                    icon = '❓'

                print(f"  {icon} Step {step_number}: {step_name}")

                # 如果步骤失败，显示详细信息
                if step_conclusion == 'failure':
                    print(f"     ⚠️ 失败原因: 查看完整日志")

            print()

        print("=" * 60)
        print("\n查看完整日志:")
        print(f"https://github.com/{owner}/{repo}/actions/runs/{run_id}")

    except urllib.error.HTTPError as e:
        print(f"❌ HTTP 错误: {e.code} - {e.reason}")
    except urllib.error.URLError as e:
        print(f"❌ 网络错误: {e.reason}")
    except Exception as e:
        print(f"❌ 错误: {e}")

if __name__ == '__main__':
    main()
