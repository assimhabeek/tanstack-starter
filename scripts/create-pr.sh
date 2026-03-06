#!/usr/bin/env bash

branch=$(git rev-parse --abbrev-ref HEAD)

gh pr create \
  --base main \
  --head "$branch" \
  --title "$title" \
  --body "$body"

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

title=$(git log --format=%s $(git merge-base main $branch)..$branch | head -n 1)
body=$(git log --format="- %s" $(git merge-base main $branch)..$branch)

gh pr create \
  --base main \
  --head "$branch" \
  --title "$title" \
  --body "$body"