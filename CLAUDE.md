# ci-templates

Public, reusable GitHub Actions workflows: `at-blacknight-projects/ci-templates`. Any
repo, including ones outside this org, calls them with
`uses: at-blacknight-projects/ci-templates/.github/workflows/<file>@v1`.

## The one rule: shared stages, thin project types

There are two layers:

- **Stages** (`stage-*.yml`) do the work. They don't know which language or project
  type they're serving, so a fix to a stage fixes every project type at once.
- **Project types** are the public API. There is one pair per *kind of thing a repo
  ships*, and each pair only lists the stages that kind needs. A container service never
  sees Helm inputs, and a CLI never sees image inputs.

Project types are about what's shipped, not the language. The language is always just
the `toolchain` input. If you're about to write the same logic in two places, or a second
copy of a stage for another language or type, stop: it belongs in the existing stage.

| Project type | Ships | `*-ci.yml` (PRs, pushes) | `*-release.yml` (release branches) |
| --- | --- | --- | --- |
| `executable` | binaries / CLIs | pr-checks, test, coverage, security, build (check) | version → bump → build → release with archives |
| `container` | an image | pr-checks, test, coverage, security, container-build (check) | version → bump → container-build → release |
| `app` | image + Helm chart | `container` + helm-lint | version → bump → container-build → helm-package → release |
| `helm` | Helm chart(s) only | pr-checks, helm-lint | version → bump → helm-package → release |
| `no-build` | nothing (config, docs, this repo) | pr-checks | version → bump → release |

"(check)" means the stage runs with `publish: false`. It builds everything a release
would (every platform, every image) but publishes nothing, so a PR proves the release
would build. Executable check builds are kept as short-lived artifacts for testing.

The stages:

```
  stage-pr-checks          PR title follows conventional commits            (PRs only)
  stage-test               toolchain setup → install → lint → audit → test → coverage.xml
  stage-coverage-report    summary, base-branch delta, sticky PR comment, threshold
  stage-security-scan      Trivy filesystem scan: gate + SARIF
  stage-helm-lint          lint, render, kubeconform
  stage-version-detect     semantic-release dry run → version, channel, prerelease
  stage-version-bump       writes the version into files → release-files
  stage-build              per platform: compile → raw binaries
  stage-package            sign (bring your own certs) → archive → SHA256SUMS → Sigstore + attestations
                                                                         (publish: false = archive only)
  stage-container-build    build → scan → push → sign                    (publish: false = check)
  stage-helm-package       package + publish charts, after images
  stage-release-semantic   tag, GitHub release, changelog commit         ALWAYS LAST
```

Project-type workflows only **wire stages together**: they map inputs onto stages and
pass outputs along, with no `run:` logic of their own. A new project type is a new
combination of existing stages. If it needs a step no stage has, add a stage that any
type could use.

### Toolchains, not languages

Only two things differ between languages: **installing the toolchain** and **the
commands**. Each stage that runs project code takes a `toolchain` input
(`go | rust | python | node | dotnet | none`):

- **Setup:** there is one conditional setup step per toolchain (`actions/setup-go`,
  `dtolnay/rust-toolchain`, `setup-python`, `setup-node`, `setup-dotnet`), and that is
  the only per-language branch allowed in a stage. Supporting a new language means adding
  a setup step and a preset row. It never means a new stage.
- **Commands:** `install-command`, `lint-command`, `audit-command`, `test-command` and
  `build-command` are inputs. When one is left empty, the stage takes it from its
  **preset table**, a single `case "$TOOLCHAIN"` block near the top of the stage.
  Presets are defaults, not special cases: any repo can override any command, and
  `toolchain: none` with explicit commands works for anything.
- **Build runners:** the build preset also chooses each platform's runner. Go and .NET
  cross-compile every OS from `ubuntu-latest`. Rust and Node build darwin on
  `macos-latest` and windows on `windows-latest`. The build command receives
  `TARGET_OS`, `TARGET_ARCH`, `VERSION`, `NAME` and `OUTPUT_DIR`, and only has to put
  files in `OUTPUT_DIR`. Archiving and checksums are the same for every language.
- **Toolchain-only extras** (Windows version resources for Go) are optional inputs, so
  other toolchains skip them. An extra that needs its own setup becomes its own stage,
  built so another toolchain could use it.
- **Containers don't care about the language.** The Dockerfile does the build, so
  `stage-container-build` has no `toolchain` input.

### Artifact contracts

These are the interfaces between stages, and the reason stages can stay language-blind.
Change one only when every producer and consumer changes in the same PR.

| Artifact | Producer | Consumer | Contents |
| --- | --- | --- | --- |
| `coverage` | `stage-test` | `stage-coverage-report` | `coverage.xml` in **Cobertura** format. Every ecosystem emits it: Go via `gocover-cobertura`, Rust via `cargo llvm-cov --cobertura`, Python via `coverage xml`, Node via Istanbul/c8 `cobertura`, .NET via coverlet. The report stage never sees a language-specific format. |
| `semantic-release-config` | `stage-version-detect` | `stage-release-semantic` | the exact config the dry run used, so the real release can't disagree with it |
| `release-files` | `stage-version-bump` | every later release stage | files edited to carry the new version (chart, pyproject, package.json, …), restored over the checkout |
| `binaries-<os>-<arch>` | `stage-build` | `stage-package` | the unsigned files the build command left in `OUTPUT_DIR` for that platform |
| `build-release` | `stage-package` | `stage-release-semantic` | `<name>-<version>-<os>-<arch>.zip` per platform, `SHA256SUMS`, and when publishing `SHA256SUMS.sigstore.json` (and `SHA256SUMS.asc` with GPG); attached to the GitHub release |

### Release ordering

The tag is created last. Version detect → bump → build everything → publish images →
publish charts (`needs` the images) → `stage-release-semantic`. A chart must never be
published for an image that doesn't exist, and a tag must never name a build that
failed. A re-run after a failure produces the same version and overwrites the earlier
partial artifacts.

### Signing: bring your own, never stored here

Signing keys and certificates are **never** in this repo, its examples, or its own
secrets. Consumers pass theirs in as optional `secrets:` (or through a protected GitHub
environment). Each kind of signing turns on only when its secrets or inputs are present.
Nothing is signed when `publish` is false, so PR builds, including same-repo PRs that
can see secrets, never touch a key.

- **Keyless by default:** Sigstore over `SHA256SUMS`, GitHub build-provenance
  attestations, and cosign for images. They need no secrets, only `id-token: write`.
- **Executables** (`stage-package`, all on Linux, so cross-compiled builds can be signed):
  - Windows Authenticode with jsign: `pkcs12` (your .pfx), `trusted-signing` or
    `key-vault` (Azure, through OIDC so there's no stored credential)
  - macOS with rcodesign: a Developer ID .p12, plus notarization if an App Store
    Connect API key is passed
  - GPG over `SHA256SUMS`
- **Handling:** secrets reach steps only through `env:`. Key material is written under
  `$RUNNER_TEMP` with `umask 077` and deleted in the same step. Passwords and tokens are
  passed to tools as `env:`/file references, never on a command line. Fetched tokens are
  masked with `::add-mask::`.
- **Approval gates:** a stage that signs takes an `environment` input. Environment
  secrets only reach a job that names the environment, so that path needs the caller to
  use `secrets: inherit`. That's the one exception to "declare secrets explicitly", and
  the reason it's allowed.
- **New providers** (AWS or Google KMS, PKCS#11) go into jsign's provider `case` in
  `stage-package`, not into a new stage.

## Writing a stage

- **File names.** The public workflows are `<type>-ci.yml` and `<type>-release.yml`.
  `stage-<what>.yml` files are building blocks; a repo with an unusual layout may call one
  directly, so they keep stable inputs too. This repo's own pipelines are `self-*.yml`.
  Everything lives in `.github/workflows/` because GitHub doesn't allow subdirectories there.
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
  **Exception: stages with a `publish` switch** (`stage-container-build`,
  `stage-package`) declare no `permissions:` at all and take what the calling job grants.
  Otherwise their release-time write permissions would become a ceiling every CI caller
  had to grant, and a check build would start with `packages`, `id-token` and
  `attestations: write` it never uses.
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
