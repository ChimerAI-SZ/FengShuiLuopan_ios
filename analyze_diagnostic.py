#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""分析签名诊断结果"""

import urllib.request
import json
import sys
import io

if sys.platform == 'win32':
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
    sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding='utf-8')

def main():
    owner = "ChimerAI-SZ"
    repo = "FengShuiLuopan_ios"
    run_id = "22558473720"  # iOS Signing Diagnostic #1
    
    print("=== 方案C: 签名诊断结果分析 ===\n")
    
    try:
        jobs_url = f"https://api.github.com/repos/{owner}/{repo}/actions/runs/{run_id}/jobs"
        req = urllib.request.Request(jobs_url)
        req.add_header('Accept', 'application/vnd.github.v3+json')
        
        with urllib.request.urlopen(req) as response:
            data = json.loads(response.read().decode('utf-8'))
            jobs = data.get('jobs', [])
            
            if jobs:
                job = jobs[0]
                print(f"Job: {job.get('name')}")
                print(f"状态: {job.get('conclusion')}")
                print(f"\n诊断步骤:\n")
                
                steps = job.get('steps', [])
                diagnostic_steps = []
                
                for step in steps:
                    step_name = step.get('name', '')
                    if '诊断' in step_name:
                        step_status = step.get('status')
                        step_conclusion = step.get('conclusion')
                        icon = '✅' if step_conclusion == 'success' else '❌' if step_conclusion == 'failure' else '⏭️'
                        diagnostic_steps.append(f"  {icon} {step_name}")
                
                for step in diagnostic_steps:
                    print(step)
                
                print(f"\n完整诊断日志:")
                print(f"https://github.com/{owner}/{repo}/actions/runs/{run_id}")
                
                print("\n" + "="*60)
                print("📋 关键信息需要从日志中提取:")
                print("="*60)
                print("1. 证书信息 (诊断 1)")
                print("   - 查看是否有 'Apple Development' 证书")
                print("   - 确认 Team ID: 66JTX3GW7T")
                print("")
                print("2. Provisioning Profile 信息 (诊断 2-3)")
                print("   - Profile 名称: FengShuiLuopan Dev")
                print("   - Bundle ID: com.fengshuizohar.ios.dev")
                print("   - Team ID: 66JTX3GW7T")
                print("   - UUID")
                print("")
                print("3. Bundle ID 匹配 (诊断 6)")
                print("   - project.yml 中的 Bundle ID")
                print("   - Profile 中的 Bundle ID")
                print("   - 是否完全匹配")
                print("")
                print("4. 构建错误 (诊断 7)")
                print("   - 具体的签名错误信息")
                print("   - 缺少什么配置")
                print("")
                print("="*60)
                print("请访问上方链接查看完整日志，找出问题所在")
                print("="*60)
                
    except Exception as e:
        print(f"错误: {e}")

if __name__ == '__main__':
    main()
