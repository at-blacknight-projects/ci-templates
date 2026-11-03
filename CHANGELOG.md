## [0.2.1](https://github.com/at-blacknight-projects/ci-templates/compare/v0.2.0...v0.2.1) (2026-11-03)

### Bug Fixes

* check SHA-pinned action refs over git, not the REST API ([7ed8efc](https://github.com/at-blacknight-projects/ci-templates/commit/7ed8efccf0cefd072c7c41bbd47ec3c0034cbb25))

## [0.2.0](https://github.com/at-blacknight-projects/ci-templates/compare/v0.1.1...v0.2.0) (2026-11-03)

### Features

* publish to a chart index with a GitHub App token ([d85ba84](https://github.com/at-blacknight-projects/ci-templates/commit/d85ba84b97ded80c642f9d356d14c7cde2217371))

## [0.1.1](https://github.com/at-blacknight-projects/ci-templates/compare/v0.1.0...v0.1.1) (2026-11-03)

### Bug Fixes

* author release commits as the identity that pushes them ([09ba5b4](https://github.com/at-blacknight-projects/ci-templates/commit/09ba5b48eea2a5d6614fe3d197c8bbe6bfe9729a))

## [0.1.0](https://github.com/at-blacknight-projects/ci-templates/compare/v0.0.0...v0.1.0) (2026-11-03)

### Features

* executable, container, app, helm and no-build workflows ([ef852df](https://github.com/at-blacknight-projects/ci-templates/commit/ef852df3395af50e6cb643b31d6b538babc6ddc4))
* self-hosted Renovate with a shared preset ([8ac1680](https://github.com/at-blacknight-projects/ci-templates/commit/8ac168055e744f9685cc26f8b4f31b892c9961c5))
* semantic-release stages read repo config and share it with the release ([b62517b](https://github.com/at-blacknight-projects/ci-templates/commit/b62517b9f23adcf9f5857b5e5d1d8bc690f1dcc1))
* shared CI stages for every toolchain and project type ([085d825](https://github.com/at-blacknight-projects/ci-templates/commit/085d825b6e96da1d16c547daad2a118c21199d53))
* toolchain-generic build and bring-your-own signing ([cafe230](https://github.com/at-blacknight-projects/ci-templates/commit/cafe2307632fffe27a5b993710a5b1a3dcdd9bf8))
* version-bump, container-build and helm-package stages ([8988f5b](https://github.com/at-blacknight-projects/ci-templates/commit/8988f5b499f7d79895002418f9ea7b5795154a2d))

### Bug Fixes

* check action refs anonymously ([8ea0c39](https://github.com/at-blacknight-projects/ci-templates/commit/8ea0c3950bb429bb80bce3aa888bae790f66547f))
* clear shellcheck findings in the test, build and helm-package stages ([442e170](https://github.com/at-blacknight-projects/ci-templates/commit/442e17034a9d5d9d4330cf470548e1fcfb1f8e10))
* compare coverage only against finished push runs on the base branch ([387f4d1](https://github.com/at-blacknight-projects/ci-templates/commit/387f4d1c1335678da6ae5cfd2e7494c61f270dc6))
* dual-mode stages take the caller's permissions ([8bcb2c8](https://github.com/at-blacknight-projects/ci-templates/commit/8bcb2c86351861a66c26013d283b9900c405ee40))
* never hand metadata-action an empty raw tag on check builds ([cfdbf04](https://github.com/at-blacknight-projects/ci-templates/commit/cfdbf048aaeca77a318180ef7d7cced923eff4d6))
* pin cosign-installer, run every check even after one fails ([b2a5583](https://github.com/at-blacknight-projects/ci-templates/commit/b2a5583aa4fb89b42dc8952b21fdbe82cbf1a7b7))
* pin the conventionalcommits preset to v9 ([ebd0a1b](https://github.com/at-blacknight-projects/ci-templates/commit/ebd0a1bb25743f41fa23a8d7f3dd360fb909f720))
* resolve SHA-pinned actions via the git commits API, and show why a ref fails ([d0017d4](https://github.com/at-blacknight-projects/ci-templates/commit/d0017d448e9f1ee6affc264181170adad27db102))

### Documentation

* document the Renovate preset and the annotation rule ([3224027](https://github.com/at-blacknight-projects/ci-templates/commit/3224027dabd210a2188b4e3405c70d85fd61639f))
