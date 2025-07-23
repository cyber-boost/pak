# MAVEN Registration Guide

## Quick Registration
1. Go to https
2. Create account with email/GitHub
3. Verify account
4. Generate API token/credentials
5. Copy credentials to clipboard

## Environment Variable
```bash
export //oss.sonatype.org/:MAVEN_USERNAME:MAVEN_PASSWORD="your_maven_token_here"
```

## Test Command
```bash
# Test your maven credentials
pak register-test maven
```
