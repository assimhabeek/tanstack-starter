#!/usr/bin/env bash

branch=$(git rev-parse --abbrev-ref HEAD)

# Skip main branches
if [[ "$branch" == "main" || "$branch" == "develop" ]]; then
  exit 0
fi

# Check if PR already exists
if gh pr view "$branch" &>/dev/null; then
  echo "PR already exists for $branch"
  exit 0
fi

echo "Creating PR for branch $branch"

gh pr create \
  --fill \
  --base main \
  --head "$branch"