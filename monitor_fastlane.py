#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""监控 Fastlane 构建进度"""

import urllib.request
import json
import time
import sys
import io

if sys.platform == 'win32':
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
    sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding='utf-8')

def check_run(run_id):
    owner = "ChimerAI-SZ"
    repo = "FengShuiLuopan_ios"

    jobs_url = f"https://api.github.com/repos/{owner}/{repo}/actions/runs/{run_id}/jobs"
    req = urllib.request.Request(jobs_url)
    req.add_header('Accept', 'application/vnd.github.v3+json')

    try:
        with urllib.request.urlopen(req) as response:
            data = json.loads(response.read().decode('utf-8'))
            jobs = data.get('jobs', [])

            if jobs:
                job = jobs[0]
                status = job.get('status')
                conclusion = job.get('conclusion')

                print(f"\n{'='*70}")
                print(f"方案A: Fastlane 构建 - Run #{run_id}")
                print(f"状态: {status}")
                if conclusion:
                    print(f"结果: {conclusion}")
                print('='*70)

                steps = job.get('steps', [])
                for step in steps:
                    step_name = step.get('name')
                    step_status = step.get('status')
                    step_conclusion = step.get('conclusion')

                    if step_status == 'completed':
                        icon = '✅' if step_conclusion == 'success' else '❌'
                        print(f"  {icon} {step_name}")
                    elif step_status == 'in_progress':
                        print(f"  🔄 {step_name} (进行中)")

                return status, conclusion
    except Exception as e:
        print(f"错误: {e}")
        return None, None

def find_latest_fastlane_run():
    """查找最新的 Fastlane 构建"""
    owner = "ChimerAI-SZ"
    repo = "FengShuiLuopan_ios"

    runs_url = f"https://api.github.com/repos/{owner}/{repo}/actions/runs?per_page=10"
    req = urllib.request.Request(runs_url)
    req.add_header('Accept', 'application/vnd.github.v3+json')

    try:
        with urllib.request.urlopen(req) as response:
            data = json.loads(response.read().decode('utf-8'))
            runs = data.get('workflow_runs', [])

            for run in runs:
                if 'Fastlane' in run.get('name', ''):
                    return run.get('id')
    except Exception as e:
        print(f"查找最新运行失败: {e}")

    return None

if __name__ == '__main__':
    print("╔" + "="*68 + "╗")
    print("║" + " "*20 + "方案A: Fastlane 构建监控" + " "*20 + "║")
    print("╚" + "="*68 + "╝")

    # 如果提供了 run_id，使用它；否则查找最新的
    if len(sys.argv) > 1:
        run_id = sys.argv[1]
        print(f"\n监控指定的 Run ID: {run_id}")
    else:
        print("\n正在查找最新的 Fastlane 构建...")
        run_id = find_latest_fastlane_run()

        if not run_id:
            print("\n❌ 未找到 Fastlane 构建")
            print("\n请先手动触发 Fastlane workflow:")
            print("  1. 访问: https://github.com/ChimerAI-SZ/FengShuiLuopan_ios/actions")
            print("  2. 选择: iOS Build with Fastlane")
            print("  3. 点击: Run workflow")
            print("\n触发后，运行: python monitor_fastlane.py <run_id>")
            sys.exit(1)

        print(f"找到 Run ID: {run_id}")

    max_attempts = 40  # 最多等待 20 分钟
    attempt = 0

    while attempt < max_attempts:
        attempt += 1
        status, conclusion = check_run(run_id)

        if status == 'completed':
            print("\n" + "╔" + "="*68 + "╗")
            if conclusion == 'success':
                print("║" + " "*24 + "🎉 构建成功！" + " "*24 + "║")
                print("╚" + "="*68 + "╝")
                print("\n✅ IPA 文件已生成！")
                print("\n📦 下载 Artifacts:")
                print(f"  https://github.com/ChimerAI-SZ/FengShuiLuopan_ios/actions/runs/{run_id}")
                print("\n包含:")
                print("  - FengShuiLuopan-IPA (IPA 文件)")
                print("  - FengShuiLuopan-dSYM (调试符号)")
                print("\n🎯 下一步:")
                print("  1. 下载 IPA 文件")
                print("  2. 使用 Xcode 或 Apple Configurator 安装到设备")
                print("  3. 测试应用功能")
            else:
                print("║" + " "*24 + "❌ 构建失败" + " "*24 + "║")
                print("╚" + "="*68 + "╝")
                print("\n查看详细日志:")
                print(f"  https://github.com/ChimerAI-SZ/FengShuiLuopan_ios/actions/runs/{run_id}")
                print("\n常见问题:")
                print("  1. Profile 不匹配 → 检查 Bundle ID 和 Profile 名称")
                print("  2. 证书问题 → 检查证书类型和有效期")
                print("  3. 导出失败 → 检查 ExportOptions.plist")
            print("\n" + "="*70)
            break

        if attempt < max_attempts:
            print(f"\n⏳ 等待 30 秒... (尝试 {attempt}/{max_attempts})")
            time.sleep(30)

    if attempt >= max_attempts:
        print("\n⏰ 监控超时")
        print(f"   请手动查看: https://github.com/ChimerAI-SZ/FengShuiLuopan_ios/actions/runs/{run_id}")
