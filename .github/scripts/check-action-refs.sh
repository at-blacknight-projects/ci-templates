#!/bin/bash
# Fails if any `uses: owner/repo[/path]@ref` in the workflows doesn't resolve to a tag,
# branch or commit. Catches pins to major tags an action never published
# (e.g. sigstore/cosign-installer has no moving v4). This repo's own refs are skipped:
# the examples in comments point at releases that may not exist yet.
set -euo pipefail
dir="${1:-.github/workflows}"
missing=0
while read -r ref; do
  repo=$(cut -d@ -f1 <<< "$ref" | cut -d/ -f1-2)
  ver=${ref##*@}
  [ "$repo" = "$GITHUB_REPOSITORY" ] && continue
  if gh api "repos/$repo/git/ref/tags/$ver" > /dev/null 2>&1 \
    || gh api "repos/$repo/git/ref/heads/$ver" > /dev/null 2>&1 \
    || gh api "repos/$repo/commits/$ver" > /dev/null 2>&1; then
    echo "ok       $ref"
  else
    echo "::error::$ref does not resolve to a tag, branch or commit"
    missing=1
  fi
done < <(grep -rhoE 'uses: *[A-Za-z0-9_.-]+/[A-Za-z0-9_./-]+@[A-Za-z0-9_.-]+' "$dir" | sed -E 's/uses: *//' | sort -u)
exit "$missing"
