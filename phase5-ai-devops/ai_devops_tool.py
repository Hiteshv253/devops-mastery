#!/usr/bin/env python3
import os
import sys
import json
import argparse
import urllib.request
import urllib.error

# Setup CLI Argument Parser
parser = argparse.ArgumentParser(description="AI DevOps Log Analyzer using Gemini API")
parser.add_argument("file", help="Path to the log or error file to analyze")
parser.add_argument("--key", help="Gemini API Key (optional, defaults to GEMINI_API_KEY environment variable)")
args = parser.parse_args()

# Retrieve API Key
api_key = args.key or os.environ.get("GEMINI_API_KEY")
if not api_key:
    print("[ERROR] Gemini API Key is missing!")
    print("Please set the GEMINI_API_KEY environment variable or pass it using --key.")
    print("Example: export GEMINI_API_KEY='your_key_here' (Linux/macOS) or $env:GEMINI_API_KEY='your_key_here' (PowerShell)")
    sys.exit(1)

# Verify File Existence
file_path = args.file
if not os.path.exists(file_path):
    print(f"[ERROR] File not found: {file_path}")
    sys.exit(1)

# Read file content
try:
    with open(file_path, "r", encoding="utf-8") as f:
        log_content = f.read()
except Exception as e:
    print(f"[ERROR] Failed to read file: {e}")
    sys.exit(1)

print(f"[*] Reading '{file_path}' ({len(log_content)} characters)...")
print("[*] Analyzing with Gemini...")

# Construct the prompt for the LLM
prompt = f"""
You are an expert Principal DevOps & Platform Engineer. 
Analyze the following error logs or output file. 

Provide a structured, production-grade report containing:
1. **Root Cause Analysis (RCA)**: Explain exactly why this failure occurred in plain English/Hinglish.
2. **Tools Involved**: Identify which technologies are failing (e.g., Kubernetes, AWS IAM, Terraform, PHP, Nginx).
3. **Troubleshooting Steps**: Provide clear step-by-step commands or verification tasks.
4. **Resolution Plan (Code/Config Fix)**: Show the exact code modifications or setup changes needed to resolve this error.

--- START OF ERROR LOGS ---
{log_content}
--- END OF ERROR LOGS ---
"""

# Call Gemini API via standard HTTP POST request (No SDK dependencies)
url = f"https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key={api_key}"
headers = {"Content-Type": "application/json"}
data = {
    "contents": [
        {
            "parts": [
                {"text": prompt}
            ]
        }
    ]
}

req = urllib.request.Request(
    url, 
    data=json.dumps(data).encode("utf-8"), 
    headers=headers, 
    method="POST"
)

try:
    with urllib.request.urlopen(req) as response:
        response_body = response.read().decode("utf-8")
        res_json = json.loads(response_body)
        
        # Extract response text
        analysis = res_json["candidates"][0]["content"]["parts"][0]["text"]
        
        print("\n=== AI DEVOPS ANALYSIS REPORT ===\n")
        print(analysis)
        print("\n=================================\n")

except urllib.error.HTTPError as e:
    print(f"\n[ERROR] API request failed with status code: {e.code}")
    print(e.read().decode("utf-8"))
    sys.exit(1)
except Exception as e:
    print(f"\n[ERROR] An unexpected error occurred: {e}")
    sys.exit(1)
