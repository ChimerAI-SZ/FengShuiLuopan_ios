#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""监控方案B v2的进度"""

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
                
                print(f"\nRun #{run_id}")
                print(f"状态: {status}")
                if conclusion:
                    print(f"结果: {conclusion}")
                
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

if __name__ == '__main__':
    run_id = "22558227821"  # Build #2
    
    print("=== 监控方案B v2: 真机架构构建测试 ===")
    print("修复: 使用 -sdk iphoneos 和 generic/platform=iOS")
    
    max_attempts = 20
    attempt = 0
    
    while attempt < max_attempts:
        attempt += 1
        status, conclusion = check_run(run_id)
        
        if status == 'completed':
            print("\n" + "="*60)
            if conclusion == 'success':
                print("✅ 构建成功！代码可以编译通过")
                print("\n下一步:")
                print("  1. 问题确认在签名配置，不是代码问题")
                print("  2. 手动触发方案C（签名诊断）")
                print("  3. 根据诊断结果调整配置")
                print("  4. 手动触发方案A（Fastlane构建）")
            else:
                print("❌ 构建仍然失败")
                print("\n可能的原因:")
                print("  - 代码编译错误")
                print("  - 依赖问题")
                print("  - 配置问题")
                print("\n需要查看详细日志:")
                print(f"  https://github.com/ChimerAI-SZ/FengShuiLuopan_ios/actions/runs/{run_id}")
            print("="*60)
            break
        
        if attempt < max_attempts:
            print(f"\n等待 30 秒后刷新... (尝试 {attempt}/{max_attempts})")
            time.sleep(30)
    
    if attempt >= max_attempts:
        print("\n超时，请手动查看构建状态")
