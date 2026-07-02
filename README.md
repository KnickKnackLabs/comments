<div align="center">

# comments

**Harvest and consume structured directives embedded in source comments.**

Turn comments into explicit, user-triggered commands.

![shape: mise + BATS](https://img.shields.io/badge/shape-mise%20%2B%20BATS-4EAA25?style=flat&logo=gnubash&logoColor=white)
[![tests: 4](https://img.shields.io/badge/tests-4-brightgreen?style=flat)](test/)
![lints: 9](https://img.shields.io/badge/lints-9-blue?style=flat)
![README: TSX](https://img.shields.io/badge/README-TSX-f472b6?style=flat)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue?style=flat)](LICENSE)

</div>

<br />

## What this is

`comments` is a generic CLI for extracting structured directives from source comments, evaluating them with nushell, and optionally writing results back to disk.

A directive is a comment body that starts with `<flags>!`. `comments` extracts those directives, evaluates the body with nushell, and can optionally replace the original comment with command output.

## Quick start

```bash
gh repo clone KnickKnackLabs/comments
cd comments

mise trust
mise install
mise run test
mise run doctor

# Optional local safety net: installs .git/hooks/pre-commit.d/codebase
codebase pre-commit
```

## Goodies baked in

| Goodie            | Why it exists                                                                                            | Where                        |
| ----------------- | -------------------------------------------------------------------------------------------------------- | ---------------------------- |
| Generated README  | TSX can count tests, list tasks, and keep docs honest in CI.                                             | `README.tsx`                 |
| Doctor hook check | Local pre-commit hooks are clone-local, so the repo can report them without pretending they are tracked. | `mise run doctor`            |
| Convention lints  | Best-practice drift gets caught as code, not folklore.                                                   | `[_.codebase].lint`          |
| Real test path    | BATS tests call tasks through `mise run`, not raw scripts.                                               | `test/test_helper.bash`      |
| Mac + Linux CI    | Bash and tooling differences show up before merge.                                                       | ubuntu-latest + macos-latest |

## Scaffold inventory

| Path                         | Status | Purpose                                     |
| ---------------------------- | ------ | ------------------------------------------- |
| `mise.toml`                  | ✓      | tools, settings, and codebase lint config   |
| `README.tsx`                 | ✓      | programmable README source                  |
| `CONTRIBUTING.md`            | ✓      | repo-entry orientation surface              |
| `.mise/tasks/test`           | ✓      | canonical BATS runner                       |
| `.mise/tasks/doctor`         | ✓      | local health check plus hook hint           |
| `.github/workflows/test.yml` | ✓      | Ubuntu/macOS CI                             |
| `test/`                      | ✓      | BATS smoke coverage                         |
| `lib/`                       | ✓      | shared runtime code starts here when needed |

## Tasks

| Task              | Description                   |
| ----------------- | ----------------------------- |
| `mise run doctor` | Check local development setup |
| `mise run test`   | Run BATS tests                |

## Design notes

1. Use ast-grep/tree-sitter to extract comment-like nodes where possible.
2. Recognize directives whose normalized comment body starts with `<flags>!`.
3. Evaluate directive bodies with nushell; context is opt-in and available at consumption time.
4. Keep the core independent of any one editor or calling workflow.
5. Write results by editing files on disk; do not require editor buffer access.

<details>
<summary><b>Current convention checks</b></summary>

This template currently asks [codebase](https://github.com/KnickKnackLabs/codebase) to run these lint rules:

```
mise-settings
bats-test-helper
bats-test-task
mcr-scope
or-true
shellcheck
gum-table
caller-pwd-contract
github-actions
```

</details>

## Validation

```bash
mise run test
codebase lint "$PWD"
readme build --check
git diff --check
```

The starter suite currently has **4 tests** and **2 public tasks**. Those numbers are read from the repo at README build time.

<div align="center">

---

<sub>
This README was generated from `README.tsx` with [KnickKnackLabs/readme](https://github.com/KnickKnackLabs/readme).<br />Comments are executable only when a human chooses to consume them.
</sub></div>
