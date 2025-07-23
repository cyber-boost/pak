# PyPI Registration Guide

## Quick Registration
1. Go to https://pypi.org/account/register/
2. Create account with email
3. Verify email address
4. Go to https://pypi.org/manage/account/token/
5. Create new token with "Entire account" scope
6. Copy token to clipboard

## Environment Variable
```bash
export PYPI_TOKEN="your_pypi_token_here"
```

## Test Command
```bash
pip install --user --upgrade twine
twine check dist/*
```
