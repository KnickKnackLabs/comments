<div align="center">

# comments

**Harvest and consume structured directives embedded in source comments.**

Turn comments into explicit, user-triggered commands.

![shape: mise + BATS](https://img.shields.io/badge/shape-mise%20%2B%20BATS-4EAA25?style=flat&logo=gnubash&logoColor=white)
[![tests: 108](https://img.shields.io/badge/tests-108-brightgreen?style=flat)](test/)
![lints: 9](https://img.shields.io/badge/lints-9-blue?style=flat)
![README: TSX](https://img.shields.io/badge/README-TSX-f472b6?style=flat)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue?style=flat)](LICENSE)

</div>

<br />

## What this is

`comments` is a generic CLI for extracting structured directives from source comments, evaluating them with nushell, and optionally writing results back to disk.

A directive is a comment body that starts with `<flags>!`. `comments` extracts those directives, evaluates the body with nushell, and can optionally replace the original comment with command output.

## Install

After this package is registered with [shiv](https://github.com/KnickKnackLabs/shiv), install it as:

```bash
shiv install comments
```

Public usage examples assume the shiv-installed command name, `comments`.

## Working from a checkout

```bash
gh repo clone KnickKnackLabs/comments
cd comments

mise trust
mise install
mise run test
mise run doctor

# Run commands through mise while developing from the checkout.
mise run dispatch --stdout examples/basic.md

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

| Task                | Description                           |
| ------------------- | ------------------------------------- |
| `mise run dispatch` | Dispatch comment directives in a file |
| `mise run doctor`   | Check local development setup         |
| `mise run test`     | Run BATS tests                        |

## Usage

A directive is a source comment whose normalized body starts with `!` or a known flag sequence such as `o!` followed by a Nushell script. Prose comments like `TODO!` are ignored.

```md
<!-- !$"run and consume me" -->

<!-- o!$"replace me with stdout" -->

<!--
o!
let rows = [1 2 3]
$rows | length
-->
```

In Markdown, directives must use standalone HTML block comments. Inline HTML comments such as `hello <!-- o!script --> world` are not supported yet; see [comments#3](https://github.com/KnickKnackLabs/comments/issues/3).

In JSX/TSX, directive comments inside expression braces must be the only content in that expression. `{/* o!script */}` is supported and the full expression wrapper is consumed/replaced; `{/* o!script */ value}` fails before execution.

Dispatch every directive in a file:

```bash
comments dispatch notes.md
```

Execute directives and write the transformed file content to stdout instead of saving it to the target file:

```bash
comments dispatch --stdout notes.md
```

Require all directive comments to succeed before applying comment transformations:

```bash
comments dispatch --atomic notes.md
```

- `!script` runs the script and consumes the directive comment.
- `o!script` runs the script and replaces the directive comment with stdout.
- `o` is currently the only supported public flag; recognized but unsupported flags fail without consuming the directive.
- Default dispatch is best-effort: failed directives remain unchanged, while successful directives are consumed/replaced.
- `--atomic` applies no comment transformations if any directive fails or is unsupported.
- If a directive mutates the target file during normal dispatch, `comments` refuses to apply stale byte-range replacements.
- `--stdout` executes directive scripts and emits the transformed file content to stdout instead of saving comment replacements to the target file.

## Supported files

The v1 supported extension set is intentionally explicit: `.md`, `.js`, `.jsx`, `.ts`, `.tsx`, `.rs`, `.go`, `.sh`, and `.py`. Unsupported extensions fail clearly instead of being treated as files with no directives. Markdown support is currently limited to standalone HTML block comments, not inline HTML comments.

## Context

Each directive script receives a structured `$context` record:

```nu
$context.file                  # absolute target file path
$context.target_dir            # parent directory of the target file
$context.caller_pwd            # COMMENTS_CALLER_PWD, or the dispatch cwd fallback
$context.lines                 # original file lines
$context.directive.flags       # flag string, e.g. "o"
$context.directive.flag_list   # flag list, e.g. ["o"]
$context.directive.range       # ast-grep byte/line range
$context.directive.text        # original comment text
$context.directive.body        # normalized comment body
$context.directive.script      # script being executed
```

## Examples

- `examples/basic.md` shows consume-only directives, output replacement, and multiline directive form.
- `examples/chat.md` is a recipe for sending a file-local note through the `chat` CLI; it is not a live directive because `chat send` has side effects.

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

The starter suite currently has **108 tests** and **3 public tasks**. Those numbers are read from the repo at README build time.

<div align="center">

---

<sub>
This README was generated from `README.tsx` with [KnickKnackLabs/readme](https://github.com/KnickKnackLabs/readme).<br />Comments are executable only when a human chooses to consume them.
</sub></div>
