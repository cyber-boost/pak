# Cargo Registration Guide

## Quick Registration
1. Go to https://crates.io/signup
2. Create account with GitHub
3. Verify GitHub authorization
4. Go to https://crates.io/settings/tokens
5. Create new token
6. Copy token to clipboard

## Environment Variable
```bash
export CARGO_REGISTRY_TOKEN="your_cargo_token_here"
```

## Test Command
```bash
cargo login
```
