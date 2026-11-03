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
  [ "$repo" = "${GITHUB_REPOSITORY:-}" ] && continue
  if [[ "$ver" =~ ^[0-9a-f]{40}$ ]]; then
    checks=("repos/$repo/git/commits/$ver")
  else
    checks=("repos/$repo/git/ref/tags/$ver" "repos/$repo/git/ref/heads/$ver")
  fi
  found=0 ; errors=""
  for path in "${checks[@]}"; do
    if out=$(gh api "$path" 2>&1); then found=1; break; fi
    errors+=" [$path: $(head -c 200 <<< "$out" | tr '\n' ' ')]"
  done
  if [ "$found" = 1 ]; then
    echo "ok       $ref"
  else
    echo "::error::$ref does not resolve to a tag, branch or commit.$errors"
    missing=1
  fi
done < <(grep -rhoE 'uses: *[A-Za-z0-9_.-]+/[A-Za-z0-9_./-]+@[A-Za-z0-9_.-]+' "$dir" | sed -E 's/uses: *//' | sort -u)
exit "$missing"
