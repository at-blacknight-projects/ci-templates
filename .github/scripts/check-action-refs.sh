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
  # Git protocol only, never the REST API: some orgs put an IP allow list on
  # token-authenticated API access (aquasecurity does), and anonymous API calls share
  # a 60/hour limit per runner IP. GitHub serves any reachable commit by SHA over git.
  found=0 ; detail=""
  if [[ "$ver" =~ ^[0-9a-f]{40}$ ]]; then
    tmp=$(mktemp -d)
    git init -q --bare "$tmp"
    if git -C "$tmp" fetch -q --depth=1 "https://github.com/$repo" "$ver" 2> "$tmp/err"; then
      found=1
    else
      detail=" ($(head -c 200 "$tmp/err" | tr '\n' ' '))"
    fi
    rm -rf "$tmp"
  elif git ls-remote --exit-code "https://github.com/$repo" "refs/tags/$ver" "refs/heads/$ver" > /dev/null 2>&1; then
    found=1
  fi
  if [ "$found" = 1 ]; then
    echo "ok       $ref"
  else
    echo "::error::$ref does not resolve to a tag, branch or commit$detail"
    missing=1
  fi
done < <(grep -rhoE 'uses: *[A-Za-z0-9_.-]+/[A-Za-z0-9_./-]+@[A-Za-z0-9_.-]+' "$dir" | sed -E 's/uses: *//' | sort -u)
exit "$missing"
