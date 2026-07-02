#!/usr/bin/env bash
# Shared fixtures for comments tests.

# Run a repo task through mise so tests exercise the real task path.
comments() {
  cd "$REPO_DIR" && mise run -q "$@"
}
export -f comments

# Run inline Nushell code from the repo root so relative `use ./lib/...` imports
# resolve the same way task entrypoints do.
comments_nu() {
  cd "$REPO_DIR" && nu -c "$1"
}
export -f comments_nu
