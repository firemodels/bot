#!/bin/bash
# Remove local branches and all local tags absent from every configured remote.
# Unmerged branches are deleted too. Checked-out branches are protected.

SCRIPTDIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)" || exit 1
FMROOT="$(cd -- "$SCRIPTDIR/../../.." && pwd)" || exit 1

process_repo() (
  repo=$1
  echo "----------------------------------------------"
  echo "repo: $repo"
  cd -- "$FMROOT/$repo" || exit 1

  # Collect every local tag; keep tags whose names exist on any remote.
  local_tags=$(git tag --list) || exit 1
  echo "git checkout master"
  if ! git checkout master; then
    echo "***Warning: cannot check out master in $repo; skipping this repository. Resolve modified files or other checkout errors and try again." >&2
    exit 1
  fi

  echo "git remote prune origin"
  if ! git remote prune origin; then
    echo "***Warning: cannot prune origin in $repo; skipping this repository." >&2
    exit 1
  fi

  remotes=$(git remote) || exit 1
  if [[ -z "$remotes" ]]; then
    echo "***Error: no remotes configured for $repo; skipping repository" >&2
    exit 1
  fi

  # Read every remote successfully before deleting any branches or tags.
  remote_refs=()
  while IFS= read -r remote; do
    if ! remote_output=$(git ls-remote --heads --tags "$remote"); then
      echo "***Error: cannot read branches and tags from remote \"$remote\" for $repo; skipping repository" >&2
      exit 1
    fi
    while IFS=$'\t' read -r hash ref; do
      [[ -n "$ref" ]] && remote_refs+=("$ref")
    done <<< "$remote_output"
  done <<< "$remotes"

  has_remote_ref() {
    local ref
    for ref in "${remote_refs[@]}"; do
      [[ "$ref" == "$1" ]] && return 0
    done
    return 1
  }
  echo ""

  branches=$(git for-each-ref --format='%(refname:strip=2)' refs/heads/) || exit 1
  current=$(git branch --show-current) || exit 1
  status=0
  while IFS= read -r branch; do
    [[ -z "$branch" ]] && continue
    if [[ "$branch" == "$current" ]]; then
      echo "Skipping checked-out branch \"$branch\""
      continue
    fi
    has_remote_ref "refs/heads/$branch" && continue
    echo "git branch -D -- \"$branch\""
    if git branch -D -- "$branch"; then
      echo "Removed local branch \"$branch\" from repository \"$repo\"."
    else
      echo "***Error: could not delete branch \"$branch\" for $repo" >&2
      status=1
    fi
  done <<< "$branches"
  echo ""

  while IFS= read -r tag; do
    [[ -z "$tag" ]] && continue
    has_remote_ref "refs/tags/$tag" && continue
    echo "git tag -d -- \"$tag\""
    if git tag -d -- "$tag"; then
      echo "Removed local tag \"$tag\" from repository \"$repo\"."
    else
      echo "***Error: could not delete tag \"$tag\" for $repo" >&2
      status=1
    fi
  done <<< "$local_tags"
  exit "$status"
)

STATUS=0
for repo in cad cfast exp fds fig out smv; do
  process_repo "$repo" || STATUS=1
  echo pausing 5 s
  sleep 5 
done
exit "$STATUS"
