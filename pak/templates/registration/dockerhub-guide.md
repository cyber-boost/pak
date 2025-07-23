# DOCKERHUB Registration Guide

## Quick Registration
1. Go to https
2. Create account with email/GitHub
3. Verify account
4. Generate API token/credentials
5. Copy credentials to clipboard

## Environment Variable
```bash
export //hub.docker.com/signup:DOCKER_USERNAME:DOCKER_PASSWORD="your_dockerhub_token_here"
```

## Test Command
```bash
# Test your dockerhub credentials
pak register-test dockerhub
```
