#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""监控方案B v3的进度 - 添加SQLite依赖后"""

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
                
                print(f"\n{'='*60}")
                print(f"Run #{run_id} - Build #3")
                print(f"状态: {status}")
                if conclusion:
                    print(f"结果: {conclusion}")
                print('='*60)
                
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
    run_id = "22558278907"  # Build #3
    
    print("╔" + "="*58 + "╗")
    print("║  监控方案B v3: 添加 SQLite.swift 依赖后的构建测试  ║")
    print("╚" + "="*58 + "╝")
    print("\n修复:")
    print("  ✓ 使用真机架构 (-sdk iphoneos)")
    print("  ✓ 添加 SQLite.swift 依赖 (SPM)")
    
    max_attempts = 25
    attempt = 0
    
    while attempt < max_attempts:
        attempt += 1
        status, conclusion = check_run(run_id)
        
        if status == 'completed':
            print("\n" + "╔" + "="*58 + "╗")
            if conclusion == 'success':
                print("║" + " "*18 + "✅ 构建成功！" + " "*18 + "║")
                print("╚" + "="*58 + "╝")
                print("\n🎉 代码可以编译通过！")
                print("\n📋 下一步行动:")
                print("  1. ✅ 确认: 问题在签名配置，不是代码")
                print("  2. 🔬 执行方案C: 手动触发签名诊断")
                print("     → GitHub Actions → iOS Signing Diagnostic → Run workflow")
                print("  3. 📊 分析诊断结果，找出签名配置问题")
                print("  4. 🚀 执行方案A: 手动触发 Fastlane 构建")
                print("     → GitHub Actions → iOS Build with Fastlane → Run workflow")
            else:
                print("║" + " "*18 + "❌ 构建失败" + " "*18 + "║")
                print("╚" + "="*58 + "╝")
                print("\n可能还有其他编译错误")
                print("\n查看详细日志:")
                print(f"  https://github.com/ChimerAI-SZ/FengShuiLuopan_ios/actions/runs/{run_id}")
            print("\n" + "="*60)
            break
        
        if attempt < max_attempts:
            print(f"\n⏳ 等待 30 秒... (尝试 {attempt}/{max_attempts})")
            time.sleep(30)
    
    if attempt >= max_attempts:
        print("\n⏰ 超时，请手动查看构建状态")
        print(f"   https://github.com/ChimerAI-SZ/FengShuiLuopan_ios/actions/runs/{run_id}")
