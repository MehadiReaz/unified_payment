# Branch Management Strategy

## Overview
This project uses a structured branching strategy for organized development and releases.

## Branch Structure

### Main Branches

#### `main`
- **Purpose**: Production-ready stable code
- **Protection**: Protected branch, no direct pushes
- **Merge Strategy**: Only accepts merge commits from `release` branch
- **Contains**: Latest stable version of the unified_payment package

#### `develop` 
- **Purpose**: Integration branch for features
- **Usage**: Default branch for development work
- **Merge Strategy**: Accepts feature branches and bug fixes
- **Contains**: Latest development changes

#### `release`
- **Purpose**: Preparation for production releases
- **Usage**: Version bumping, final testing, documentation updates
- **Merge Strategy**: Created from `develop`, merged to `main` after testing
- **Contains**: Release candidates

### Feature Branches

#### Naming Convention
```
feature/payment-provider-stripe
feature/webview-integration
feature/error-handling
bugfix/payment-response-parsing
hotfix/critical-security-patch
```

#### Workflow
1. Create from `develop`: `git checkout -b feature/feature-name develop`
2. Work on feature with regular commits
3. Push to remote: `git push origin feature/feature-name`
4. Create Pull Request to `develop`
5. After review, merge and delete feature branch

## Workflow Examples

### Adding New Payment Provider
```bash
# Create feature branch
git checkout develop
git pull origin develop
git checkout -b feature/payment-provider-square

# Work on implementation
# ... make changes ...
git add .
git commit -m "Add Square payment provider integration"

# Push and create PR
git push origin feature/payment-provider-square
# Create PR on GitHub: feature/payment-provider-square -> develop
```

### Creating Release
```bash
# Create release branch from develop
git checkout develop
git pull origin develop
git checkout -b release/v1.1.0

# Update version numbers
# Update CHANGELOG.md
# Final testing
git add .
git commit -m "Prepare release v1.1.0"

# Push release branch
git push origin release/v1.1.0

# After testing, merge to main
git checkout main
git merge --no-ff release/v1.1.0
git tag v1.1.0
git push origin main --tags

# Also merge back to develop
git checkout develop
git merge --no-ff release/v1.1.0
git push origin develop

# Clean up
git branch -d release/v1.1.0
git push origin --delete release/v1.1.0
```

### Hotfix Process
```bash
# Create hotfix from main
git checkout main
git pull origin main
git checkout -b hotfix/critical-security-fix

# Fix the issue
git add .
git commit -m "Fix critical security vulnerability"

# Merge to main
git checkout main
git merge --no-ff hotfix/critical-security-fix
git tag v1.0.1
git push origin main --tags

# Also merge to develop
git checkout develop
git merge --no-ff hotfix/critical-security-fix
git push origin develop

# Clean up
git branch -d hotfix/critical-security-fix
```

## Branch Protection Rules (GitHub)

### `main` branch
- Require pull request reviews
- Require status checks to pass
- Require branches to be up to date
- Include administrators in restrictions

### `develop` branch  
- Require pull request reviews
- Require status checks to pass
- Allow force pushes for maintainers

## Current Status
- ✅ `main`: Production code with unified_payment v1.0.0
- ✅ `develop`: Ready for feature development
- ✅ `release`: Ready for future release preparation

## Quick Commands
```bash
# Switch to development
git checkout develop
git pull origin develop

# Create feature branch
git checkout -b feature/new-feature develop

# List all branches
git branch -a

# Delete merged feature branch
git branch -d feature/completed-feature
git push origin --delete feature/completed-feature

# Sync with remote
git fetch --all --prune
```