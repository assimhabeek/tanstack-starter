#!/usr/bin/env bash

branch=$(git rev-parse --abbrev-ref HEAD)

regex='^(feat|fix|chore|docs|refactor|test|ci|build|perf)/[a-z0-9._-]+$'

if [[ ! $branch =~ $regex ]]; then
  echo "❌ Invalid branch name: $branch"
  echo ""
  echo "Expected format:"
  echo "type/description"
  echo ""
  echo "Examples:"
  echo "  feat/add-login"
  echo "  fix/api-timeout"
  echo "  chore/update-deps"
  exit 1
fi