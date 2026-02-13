#!/bin/bash
# Script to create GitHub repo and push (run after gh auth login)

REPO_NAME="${1:-ralph-test}"

echo "Creating GitHub repository: $REPO_NAME"
gh repo create "$REPO_NAME" --public --source=. --description "Ralph-tui OpenCode integration test"

echo "Pushing to GitHub..."
git branch -M main
git remote add origin "https://github.com/$(gh api user --jq .login)/$REPO_NAME.git"
git push -u origin main

echo "Done! Repository URL: https://github.com/$(gh api user --jq .login)/$REPO_NAME"
