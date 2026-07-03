# Contributing

`comments` is a KnickKnackLabs tool for harvesting and consuming structured directives embedded in source comments.

The v1 path is intentionally small:

1. extract comment-like nodes from files with ast-grep/tree-sitter,
2. recognize directives whose comment body starts with `<flags>!`,
3. evaluate the directive body with nushell, and
4. optionally write command output back to the directive region on disk.

Keep the tool generic: comment extraction, directive evaluation, and optional file write-back belong here; workflow-specific integrations belong at the edges.

## Local setup

```bash
mise trust
mise install
mise run test
mise run doctor
```

`doctor` reports whether the optional local `codebase pre-commit` hook is installed.
Install it in your clone when you want convention lints to run before every commit:

```bash
codebase pre-commit
```

## Structure

```text
comments/
├── mise.toml              # Tools, settings, codebase lint config
├── README.tsx             # Source for generated README.md
├── README.md              # Generated; keep in sync with README.tsx
├── CONTRIBUTING.md        # Repo orientation surface
├── .mise/tasks/test       # Canonical BATS runner
├── .mise/tasks/doctor     # Local health checks + optional hook status
├── lib/                   # Shared runtime code starts here when needed
└── test/                  # BATS tests and helpers
```

## Validation before merge

```bash
mise run test
codebase lint "$PWD"
readme build --check
git diff --check
```
