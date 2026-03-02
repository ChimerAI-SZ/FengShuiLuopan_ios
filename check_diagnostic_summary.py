#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""检查诊断和最近构建的状态"""

import urllib.request
import json
import sys
import io

if sys.platform == 'win32':
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
    sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding='utf-8')

def check_run(run_id, title):
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
                print(f"\n{'='*60}")
                print(f"{title}")
                print('='*60)
                
                steps = job.get('steps', [])
                for step in steps:
                    step_name = step.get('name', '')
                    step_conclusion = step.get('conclusion')
                    
                    if step_conclusion == 'failure':
                        print(f"❌ 失败步骤: {step_name}")
                    elif step_conclusion == 'success' and ('Build' in step_name or 'Export' in step_name or '诊断' in step_name):
                        print(f"✅ {step_name}")
                
    except Exception as e:
        print(f"错误: {e}")

if __name__ == '__main__':
    print("=== 诊断和构建状态总结 ===")
    
    # 诊断结果
    check_run("22558473720", "方案C: 签名诊断 (#1)")
    
    # 最近的签名构建失败
    check_run("22558455676", "最近的签名构建 (#23)")
    
    print("\n" + "="*60)
    print("📋 建议:")
    print("="*60)
    print("1. 如果诊断步骤 7 显示了具体错误，需要先修复")
    print("2. 如果 Bundle ID 不匹配，需要调整 project.yml")
    print("3. 如果证书或 Profile 有问题，需要重新配置 Secrets")
    print("4. 如果一切正常，可以直接执行方案A (Fastlane)")
    print("="*60)
