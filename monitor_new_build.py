#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""监控新构建的进度"""

import urllib.request
import json
import time
import sys
import io

# Windows 控制台 UTF-8 支持
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
                
                print(f"Run #{run_id}")
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
    # 监控无签名构建测试
    run_id = "22558115343"
    
    print("=== 监控方案B: 无签名构建测试 ===\n")
    
    while True:
        status, conclusion = check_run(run_id)
        
        if status == 'completed':
            print("\n" + "="*50)
            if conclusion == 'success':
                print("✅ 构建成功！代码可以编译通过")
                print("下一步: 运行方案C（签名诊断）")
            else:
                print("❌ 构建失败，代码有编译错误")
                print("需要先修复代码问题")
            print("="*50)
            break
        
        print("\n等待 30 秒后刷新...\n")
        time.sleep(30)
