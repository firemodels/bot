#!/bin/bash

CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" || exit 1

if [[ "${1:-}" == -h ]]; then
  cat <<'EOF'
Usage: ./ShowRevTags.sh [-h]

Show the current Git revision and branch alongside the release tag and revision
recorded in config.sh for each bundle repository.

  -h  Show this help and exit.
EOF
  exit 0
fi

source ./config.sh || exit 1
gitroot="$(cd ../../.. && pwd)" || exit 1

GETREV ()
{
  local repo="$1" config_version="$2" config_tag="$3"
  local repo_dir="$gitroot/$repo" worktree repo_version branch

  # At a worktree root, Git reports true followed by an empty path prefix.
  if ! worktree=$(git -C "$repo_dir" rev-parse --is-inside-work-tree --show-prefix 2>/dev/null) ||
     [[ "$worktree" != true ]]; then
    printf 'Warning: skipping %s (%s), which is not a Git worktree root.\n' "$repo" "$repo_dir" >&2
    return 0
  fi

  repo_version=$(git -C "$repo_dir" describe --always --dirty --long) || return 1
  branch=$(git -C "$repo_dir" branch --show-current) || return 1

  printf 'repo   %s/%s\nconfig %s/%s\n\n' "$repo_version" "$branch" "$config_tag" "$config_version"
}

GETREV bot   "$BUNDLE_BOT_HASH"   "$BUNDLE_BOT_TAG"
GETREV cad   "$BUNDLE_CAD_HASH"   "$BUNDLE_CAD_TAG"
GETREV cfast "$BUNDLE_CFAST_HASH" "$BUNDLE_CFAST_TAG"
GETREV exp   "$BUNDLE_EXP_HASH"   "$BUNDLE_EXP_TAG"
GETREV fds   "$BUNDLE_FDS_HASH"   "$BUNDLE_FDS_TAG"
GETREV fig   "$BUNDLE_FIG_HASH"   "$BUNDLE_FIG_TAG"
GETREV out   "$BUNDLE_OUT_HASH"   "$BUNDLE_OUT_TAG"
GETREV smv   "$BUNDLE_SMV_HASH"   "$BUNDLE_SMV_TAG"
