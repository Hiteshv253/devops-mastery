# AI-Driven DevOps Troubleshooting Tool

This tool leverages the **Google Gemini API** to automatically analyze DevOps-related failures, suggest fixes, and output step-by-step resolution scripts. It uses pure Python libraries (`urllib`) and has **zero external library dependencies**.

---

## Prerequisites
- **Python 3.x** installed.
- A **Gemini API Key**. You can get a free key from [Google AI Studio](https://aistudio.google.com/).

---

## How to Run the Tool

### Step 1: Set your API Key in your shell
Set your API key as an environment variable (replace with your actual key):

**In Windows (PowerShell):**
```powershell
$env:GEMINI_API_KEY="AIzaSy..."
```

**In Linux/macOS:**
```bash
export GEMINI_API_KEY="AIzaSy..."
```

### Step 2: Run the script against a log file

#### Test 1: Analyze a failing Kubernetes Pod
Run the analyzer on the sample Kubernetes database timeout log:
```bash
python ai_devops_tool.py k8s_crash.log
```

#### Test 2: Analyze a failing Terraform Plan
Run the analyzer on the sample Terraform access denied/missing resources output:
```bash
python ai_devops_tool.py terraform_fail.txt
```

---

## Customizing the AI Prompt
You can edit the system prompt inside `ai_devops_tool.py` to match your specific corporate standards, such as outputting answers in specific templates or targeting specific cloud environments (e.g. "Suggest fixes matching AWS security guidelines").
