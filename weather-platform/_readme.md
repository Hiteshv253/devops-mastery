.venv/bin/python -m pip install --upgrade pip
.venv/bin/python -m pip install -r requirements.txt

pip install -r requirements.txt

uvicorn app.main:app --reload

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




cleaup folders
find . \
  \( -name "__pycache__" \
  -o -name ".pytest_cache" \
  -o -name ".mypy_cache" \
  -o -name ".ruff_cache" \) \
  -type d -exec rm -rf {} + && \
find . \( -name "*.pyc" -o -name "*.pyo" \) -type f -delete