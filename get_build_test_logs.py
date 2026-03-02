#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""获取无签名构建测试的详细日志"""

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
    
    print(f"=== 获取构建测试日志 (Run #{run_id}) ===\n")
    
    try:
        jobs_url = f"https://api.github.com/repos/{owner}/{repo}/actions/runs/{run_id}/jobs"
        req = urllib.request.Request(jobs_url)
        req.add_header('Accept', 'application/vnd.github.v3+json')
        
        with urllib.request.urlopen(req) as response:
            data = json.loads(response.read().decode('utf-8'))
            jobs = data.get('jobs', [])
            
            if jobs:
                job = jobs[0]
                
                # 获取日志 URL
                logs_url = job.get('url')
                if logs_url:
                    logs_url = logs_url.replace('/jobs/', '/jobs/') + '/logs'
                    
                    print(f"日志 URL: {logs_url}\n")
                    
                    # 获取日志内容
                    log_req = urllib.request.Request(logs_url)
                    log_req.add_header('Accept', 'application/vnd.github.v3+json')
                    
                    with urllib.request.urlopen(log_req) as log_response:
                        logs = log_response.read().decode('utf-8')
                        
                        # 查找 Build Without Signing 步骤的日志
                        lines = logs.split('\n')
                        in_build_step = False
                        error_lines = []
                        
                        for line in lines:
                            if 'Build Without Signing' in line:
                                in_build_step = True
                            elif in_build_step:
                                if line.startswith('##[group]') or line.startswith('##[endgroup]'):
                                    continue
                                if 'error:' in line.lower() or 'fatal' in line.lower():
                                    error_lines.append(line)
                                if len(error_lines) > 50:
                                    break
                        
                        if error_lines:
                            print("=== 编译错误 ===\n")
                            for line in error_lines[:30]:
                                print(line)
                        else:
                            print("未找到明确的错误信息，显示最后100行日志:\n")
                            for line in lines[-100:]:
                                print(line)
                
    except Exception as e:
        print(f"错误: {e}")
        import traceback
        traceback.print_exc()

if __name__ == '__main__':
    main()
