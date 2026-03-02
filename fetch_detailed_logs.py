#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""获取详细的构建日志"""

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
    run_id = "22558115343"
    
    print(f"=== 分析构建失败原因 ===\n")
    
    try:
        # 获取 jobs
        jobs_url = f"https://api.github.com/repos/{owner}/{repo}/actions/runs/{run_id}/jobs"
        req = urllib.request.Request(jobs_url)
        req.add_header('Accept', 'application/vnd.github.v3+json')
        
        with urllib.request.urlopen(req) as response:
            data = json.loads(response.read().decode('utf-8'))
            jobs = data.get('jobs', [])
            
            if jobs:
                job = jobs[0]
                steps = job.get('steps', [])
                
                # 找到失败的步骤
                for step in steps:
                    if step.get('name') == 'Build Without Signing' and step.get('conclusion') == 'failure':
                        print("找到失败步骤: Build Without Signing")
                        print(f"步骤结论: {step.get('conclusion')}")
                        print(f"\n完整日志链接:")
                        print(f"https://github.com/{owner}/{repo}/actions/runs/{run_id}")
                        print("\n根据截图，构建失败 exit code 70")
                        print("\nexit code 70 通常表示:")
                        print("  - 内部软件错误")
                        print("  - xcodebuild 无法找到指定的 destination")
                        print("  - 模拟器不可用或配置错误")
                        print("\n建议:")
                        print("  1. 改用真机架构构建 (-sdk iphoneos)")
                        print("  2. 使用通用 destination (generic/platform=iOS)")
                        print("  3. 或者简化 destination 参数")
                        break
                
    except Exception as e:
        print(f"错误: {e}")

if __name__ == '__main__':
    main()
