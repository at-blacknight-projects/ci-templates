# ci-templates

Reusable GitHub Actions workflows for building, testing, signing and releasing any
project. Pick the pair that matches **what your repo ships**; the language is just an
input.

| You ship | CI (pull requests, pushes) | Release (release branches) |
| --- | --- | --- |
| Binaries / CLIs | `executable-ci.yml` | `executable-release.yml` |
| A container image | `container-ci.yml` | `container-release.yml` |
| An image + its Helm chart | `app-ci.yml` | `app-release.yml` |
| Helm charts only | `helm-ci.yml` | `helm-release.yml` |
| Nothing built (config, docs) | `no-build-ci.yml` | `no-build-release.yml` |

Toolchains: `go`, `rust`, `python`, `node`, `dotnet`, or `none` with your own
commands. Every preset command can be overridden.

## Quick start: a Go CLI

`.github/workflows/ci.yml`

```yaml
name: CI
on:
  pull_request:
  push:
    branches: [main]
permissions:
  contents: read
  actions: read
  pull-requests: write
  security-events: write
jobs:
  ci:
    uses: at-blacknight-projects/ci-templates/.github/workflows/executable-ci.yml@v1
    with:
      toolchain: go
      coverage-threshold: 70
```

`.github/workflows/release.yml`

```yaml
name: Release
on:
  push:
    branches: [main, alpha]
permissions:
  contents: write
  issues: write
  pull-requests: write
  id-token: write
  attestations: write
jobs:
  release:
    uses: at-blacknight-projects/ci-templates/.github/workflows/executable-release.yml@v1
    with:
      toolchain: go
    secrets:
      app-id: ${{ secrets.RELEASE_APP_ID }}                 # optional, see below
      app-private-key: ${{ secrets.RELEASE_APP_PRIVATE_KEY }}
```

## Quick start: a service with a Helm chart

```yaml
jobs:
  ci:
    uses: at-blacknight-projects/ci-templates/.github/workflows/app-ci.yml@v1
    with:
      toolchain: python
      images: '[{"name": "", "context": ".", "file": "Dockerfile"}]'
      charts: helm/my-service
```

```yaml
jobs:
  release:
    uses: at-blacknight-projects/ci-templates/.github/workflows/app-release.yml@v1
    with:
      charts: helm/my-service
      chart-values: .image.tag          # set to the release version
    secrets:
      app-id: ${{ secrets.RELEASE_APP_ID }}
      app-private-key: ${{ secrets.RELEASE_APP_PRIVATE_KEY }}
```

Images go to `ghcr.io/<owner>/<repo>`, charts to `oci://ghcr.io/<owner>/charts`.

## What you get

- **PR checks.** The PR title must be a conventional commit. Tests run with
  coverage, and one PR comment shows the total and its change against the base branch,
  with an optional threshold. A Trivy scan fails the check on high or critical findings
  and sends every finding to the Security tab. Charts are linted and validated with
  kubeconform.
- **Check builds.** PRs build every platform and image a release would. Nothing is
  published, so a broken release shows up on the PR, not after merging.
- **Releases.** semantic-release picks the version from conventional commits. That
  version is written into charts and files, everything is built and published, and only
  then are the tag, GitHub release and changelog commit created. A failed build never
  leaves a tag behind.
- **Pre-releases.** Pushes to `alpha`, `dev`, `uat` or `rc` make `1.2.0-alpha.N` and
  tag images with the channel name. Bring your own `.releaserc` to change the branches.
- **Supply chain.** Images get SBOMs, provenance and keyless cosign signatures.
  Executables get `SHA256SUMS` with a Sigstore signature and build-provenance
  attestations.

## Signing executables with your own certificates

There are no keys in this repo. Pass yours as secrets. Each kind of signing turns on
when its secrets are present, and PR builds never sign.

| Platform | Secrets / inputs |
| --- | --- |
| Windows, your .pfx | `windows-pfx-base64`, `windows-pfx-password` |
| Windows, Azure Trusted Signing | `windows-sign-provider: trusted-signing`, `windows-keystore` (endpoint), `windows-alias` (account/profile), `azure-client-id`, `azure-tenant-id` (OIDC, no stored secret) |
| Windows, Azure Key Vault | `windows-sign-provider: key-vault`, `windows-keystore` (vault), `windows-alias` (certificate), `azure-client-id`, `azure-tenant-id` |
| macOS | `macos-p12-base64`, `macos-p12-password`; add `apple-api-issuer-id`, `apple-api-key-id`, `apple-api-key-p8` to notarize |
| Checksums (GPG) | `gpg-private-key`, `gpg-passphrase` |

All of it runs on Linux, so Go cross-compiled binaries can be signed for Windows and
macOS. To require approval before anything is signed, store the secrets in a protected
GitHub environment, set `environment:`, and call the workflow with `secrets: inherit`.

## Releasing past branch protection

semantic-release pushes a release commit and a tag. If your branches are protected,
create a GitHub App that is allowed to bypass, store its ID and private key as secrets,
and pass them as `app-id` and `app-private-key`. Without them the workflows use
`GITHUB_TOKEN`.

## Dependency updates (Renovate)

Extend the shared policy in your repo's `renovate.json`:

```json
{ "extends": ["github>at-blacknight-projects/ci-templates"] }
```

What the policy does:
- **Commit types that suit semantic-release.** Runtime dependencies, toolchains and base
  images commit as `fix(deps):`, so they ship a patch release. CI and tooling commit as
  `chore(deps):` and release nothing.
- **When updates arrive.** Routine PRs open before 6am UTC on Mondays. Vulnerability
  fixes open at any time.
- **Auto-merge.** Non-major GitHub Actions and annotated tool updates merge themselves
  once CI passes. Majors always wait for review.
- **Go toolchain.** The `toolchain` line in `go.mod` and the `golang` image tag move in
  one PR, because official golang images ignore `go.mod`'s toolchain.
- **Pins in scripts.** Versions inside scripts are tracked through `# renovate:`
  comments (see `annotations.json`).

To run Renovate yourself instead of using a hosted service, call `renovate.yml` on a
schedule with your own GitHub App. The header of `renovate.yml` lists the permissions the
app needs.

## Versioning

Pin a major version: `@v1`. It moves to each compatible release, while `@v1.2.3` pins
exactly. Breaking changes to inputs, outputs or behaviour only ship in a new major
version.

## Contributing

See [CLAUDE.md](CLAUDE.md) for the structure: shared stages, thin project types, and
the artifact contracts between them. Commits follow
[conventional commits](docs/conventional-commits.md).
