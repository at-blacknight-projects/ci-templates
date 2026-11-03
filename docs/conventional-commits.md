# Conventional Commits Guide

This guide explains how to write conventional commits for automatic versioning with semantic-release.

## Format

```
<type>[optional scope]: <description>

[optional body]

[optional footer]
```

## Commit Types

### Release Types (Trigger Version Bumps)

#### `feat:` - New Feature (Minor Bump)
Adds new functionality.

**Example:**
```
feat: add user authentication
```

**Result:** 1.2.0 → 1.3.0

#### `fix:` - Bug Fix (Patch Bump)
Fixes a bug.

**Example:**
```
fix: resolve login timeout issue
```

**Result:** 1.2.0 → 1.2.1

#### `perf:` - Performance Improvement (Patch Bump)
Improves performance without changing functionality.

**Example:**
```
perf: optimize database queries
```

**Result:** 1.2.0 → 1.2.1

#### Breaking Changes (Major Bump)
Add `!` after type or `BREAKING CHANGE:` in footer.

**Example:**
```
feat!: change API response format

BREAKING CHANGE: API now returns JSON instead of XML
```

**Result:** 1.2.0 → 2.0.0

### Non-Release Types (No Version Bump)

#### `docs:` - Documentation
Documentation changes only.

**Example:**
```
docs: update README installation instructions
```

**Result:** No release

#### `style:` - Code Style
Formatting, whitespace, missing semicolons, etc.

**Example:**
```
style: format code with gofmt
```

**Result:** No release

#### `refactor:` - Code Refactoring
Code changes that neither fix bugs nor add features.

**Example:**
```
refactor: extract validation logic to separate function
```

**Result:** No release

#### `test:` - Tests
Adding or updating tests.

**Example:**
```
test: add unit tests for authentication
```

**Result:** No release

#### `chore:` - Maintenance
Build process, dependencies, tooling.

**Example:**
```
chore: update dependencies
```

**Result:** No release

#### `ci:` - CI/CD
Changes to CI/CD configuration.

**Example:**
```
ci: add automated testing workflow
```

**Result:** No release

#### `build:` - Build System
Changes to build system or external dependencies.

**Example:**
```
build: update go version to 1.24
```

**Result:** No release

## Scopes (Optional)

Scopes provide additional context about what part of the codebase changed.

**Example:**
```
feat(auth): add OAuth2 support
fix(api): handle null responses
docs(readme): add installation steps
```

## Multi-Paragraph Commits

Use the body to provide more context.

**Example:**
```
feat: add dark mode support

This adds a dark mode toggle to the settings page.
The theme preference is stored in localStorage and
persists across sessions.
```

## Breaking Changes

### Method 1: `!` After Type
```
feat!: remove deprecated API endpoints
```

### Method 2: Footer
```
feat: update authentication flow

BREAKING CHANGE: The /login endpoint now requires a client_id parameter
```

### Method 3: Both
```
feat!: rewrite configuration system

BREAKING CHANGE: Configuration format changed from JSON to YAML
```

## Real-World Examples

### Feature Development
```
feat(templates): add support for custom functions

Users can now register custom template functions:
- FuncMap registration
- Built-in helper functions
- Function documentation
```

**Result:** 1.5.0 → 1.6.0

### Bug Fix
```
fix(parser): handle escaped quotes in strings

Previously, strings with escaped quotes would cause
parser errors. This fix properly handles \\" sequences.

Fixes #123
```

**Result:** 1.5.0 → 1.5.1

### Breaking Change
```
feat!: migrate to new configuration format

BREAKING CHANGE: Configuration files must now use YAML instead of JSON.
Migration tool available: migrate-config command.

Old format:
{
  "setting": "value"
}

New format:
setting: value
```

**Result:** 1.5.0 → 2.0.0

### Documentation
```
docs: add examples for template functions

Added examples for:
- Basic template usage
- Custom function registration
- Error handling
```

**Result:** No release

### Chore
```
chore: update dependencies to latest versions
```

**Result:** No release

## Branch Strategies

### Main Branch (Stable Releases)
Commits to `main` create stable releases:
- `feat:` → 1.2.0 → 1.3.0
- `fix:` → 1.2.0 → 1.2.1
- `feat!:` → 1.2.0 → 2.0.0

### UAT Branch (Release Candidates)
Commits to `uat` create pre-releases:
- `feat:` → 1.2.0 → 1.3.0-rc.1
- `fix:` → 1.2.0-rc.1 → 1.2.0-rc.2

### Develop Branch (Beta Releases)
Commits to `develop` create beta releases:
- `feat:` → 1.2.0 → 1.3.0-beta.1
- `fix:` → 1.2.0-beta.1 → 1.2.0-beta.2

## Tips

### Do's ✅
- Keep the description concise (< 50 characters)
- Use imperative mood ("add feature" not "added feature")
- Reference issue numbers in footer (`Fixes #123`)
- Explain *why* in the body, not *what* (code shows what)
- Use breaking changes sparingly

### Don'ts ❌
- Don't use past tense ("added feature")
- Don't include multiple changes in one commit
- Don't omit type prefix
- Don't use vague descriptions ("fix stuff", "update code")

## Validation

Your commits will be validated by semantic-release. Invalid commits won't trigger releases but won't block merges.

**Valid:**
```
feat: add feature
fix: bug fix
feat!: breaking change
```

**Invalid (won't trigger release):**
```
Add feature (missing type)
feat add feature (missing colon)
updated docs (wrong tense)
```

## Resources

- [Conventional Commits Specification](https://www.conventionalcommits.org/)
- [Semantic Versioning](https://semver.org/)
- [How to Write a Git Commit Message](https://chris.beams.io/posts/git-commit/)

## Getting Help

If you're unsure which type to use:

1. Does it add functionality? → `feat:`
2. Does it fix a bug? → `fix:`
3. Is it a breaking change? → Add `!` or `BREAKING CHANGE:`
4. Is it documentation/chore? → Use appropriate non-release type

When in doubt, ask in pull request comments!
