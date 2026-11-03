# ci-templates

Public, reusable GitHub Actions workflows: `at-blacknight-projects/ci-templates`. Any
repo, including ones outside this org, calls them with
`uses: at-blacknight-projects/ci-templates/.github/workflows/<file>@v1`.

## The one rule: shared stages, thin project types

Every project type (Go, Python, container-only, Helm-only, no-build) goes through the
**same pipeline shape**, built from the **same shared stages**. A fix to a shared stage
must fix every project type at once. If you're about to write the same logic in two
places, it belongs in a stage.

```
CI (PRs and pushes)
  stage-pr-checks          shared   PR title / conventional commits
  stage-<lang>-test        per-lang lint, test, coverage → coverage-summary.json
  stage-coverage-report    shared   summary, base-branch delta, PR comment, threshold
  stage-security-scan      shared   Trivy filesystem scan (gate + SARIF)
  stage-helm-lint          shared   only when the repo has charts

Release (push to a release branch)
  stage-version-detect     shared   semantic-release dry run → version, channel
  stage-version-bump       shared   writes the version into files → release-files artifact
  stage-<lang>-build       per-lang binaries (e.g. stage-go-build-matrix) → build-* artifacts
  stage-container-build    shared   build → scan → push → sign images
  stage-helm-package       shared   bump, package, publish charts (after images)
  stage-release-semantic   shared   tag, GitHub release, changelog commit: ALWAYS LAST
```

`<type>-ci.yml` and `<type>-release.yml` are the public API. They only **wire stages
together**, mapping their inputs onto stage inputs and passing outputs along. They contain
no `run:` logic of their own. If a project-type workflow needs a step, add it to the
right stage (or make a new stage) and call that.

Per-language stages do only the language-specific part and hand off through the
**artifact contracts** below. Everything downstream of a contract is shared.

### Artifact contracts

These are the interfaces between stages. Change one only when every producer and
consumer changes in the same PR.

| Artifact | Producer | Consumer | Contents |
| --- | --- | --- | --- |
| `coverage-summary` | `stage-<lang>-test` | `stage-coverage-report` | `coverage-summary.json`: `{"total", "covered", "statements", "packages": [{"name", "pct", "covered", "statements"}]}`, plus the raw report |
| `semantic-release-config` | `stage-version-detect` | `stage-release-semantic` | the exact config the dry run used, so the real release can't disagree with it |
| `release-files` | `stage-version-bump` | build stages, `stage-release-semantic` | files edited to carry the new version (chart, pyproject, …), restored over the checkout |
| `build-*` | `stage-<lang>-build` | `stage-release-semantic` | release assets attached to the GitHub release |

### Release ordering

The tag is created last. Version detect → bump → build everything → publish images →
publish charts (`needs` the images) → `stage-release-semantic`. A chart must never be
published for an image that doesn't exist, and a tag must never name a build that
failed. A re-run after a failure produces the same version and overwrites the earlier
partial artifacts.

## Writing a stage

- **File names.** `stage-<what>.yml` is internal (consumers don't call it). Public
  workflows are `<type>-ci.yml` and `<type>-release.yml`. Everything is in
  `.github/workflows/` because GitHub doesn't allow subdirectories there.
- **Calling other stages.** Use `uses: ./.github/workflows/stage-x.yml`. Inside a reusable
  workflow this resolves to *this* repo at the same ref as the caller pinned, so a
  consumer on `@v1` gets a consistent set.
- **Reuse before you write.** Start from an existing stage. Prefer an established action
  (setup-*, golangci-lint-action, trivy-action, docker/*, azure/setup-helm,
  create-github-app-token) over shell. Shell is for glue and for the artifact contracts.
- **Inputs.** Use kebab-case and give every input a `description` and a default that
  works for the common case. Booleans turn features on or off; don't overload strings to
  do that. Lists are newline-separated strings. JSON is only for structured lists such as
  images.
- **Secrets.** Declare them explicitly; never require `secrets: inherit`. The release
  identity is always the optional pair `app-id` + `app-private-key` (a GitHub App token
  that can push past branch protection). Without them, fall back to `github.token`.
- **Permissions.** Default to `permissions: contents: read` at workflow level and grant
  more per job, at the minimum needed. Document in the stage header what the caller has
  to grant, since a called workflow can't get more than its caller has.
- **Untrusted values.** Never interpolate `${{ inputs.* }}` or `${{ github.event.* }}`
  straight into `run:`. Pass them through `env:` and quote them.
- **Fork PRs.** They get a read-only token. Steps that write (PR comments, SARIF
  upload) use `continue-on-error: true` and report in the job summary instead.
- **Header comment.** Each stage opens with a comment saying what it does, which
  contracts it consumes and produces, and anything a caller must grant.

## Versions and pinning

- Actions are pinned to a major tag (`actions/checkout@v7`). The exception is
  `aquasecurity/trivy-action`, which is pinned to a commit SHA with the tag in a comment,
  because of that action's history.
- npm tools are pinned to a major version (`semantic-release@25`), and the at-blacknight
  plugins to an exact version.
- This repo releases itself with its own stages: semantic-release from conventional
  commits, then the moving major tag (`v1`) is updated to the new release. The base tag
  is `v0.0.0`.
- Breaking changes to any public workflow's inputs, outputs or artifact contracts are
  `feat!:` and need a new major tag.

## Validate before committing

```
actionlint .github/workflows/*.yml
```

actionlint runs shellcheck on `run:` blocks when shellcheck is installed. Fix the
findings rather than suppressing them; a suppression needs a comment saying why. Behaviour
can only be tested by a real consumer run: point a test repo or PR at the branch (`@<branch>`) before merging.

## Public repo: organisation-neutral

Anyone can read this repo. Never put an employer's or client's hostnames, IPs, tenant
or app IDs, internal repo names, ticket keys or product names in code, comments, docs,
examples or commit messages. Use `example.com`, `192.0.2.x`, `ghcr.io/example/app`.

The clone's `core.hooksPath` points at a pre-commit and commit-msg denylist kept outside
the repo (committing the list would publish the terms). Don't bypass it with
`--no-verify`.

## Git

- Commit as `at-blacknight <github@at-blacknight.com>` (set in the repo-local config).
- Use conventional commits, because they drive the version (see `docs/conventional-commits.md`).
- No AI attribution in commits or PRs: no `Co-Authored-By`, no "Generated with".
- Work in a branch or worktree and open a PR into `main`.
