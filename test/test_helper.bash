#!/usr/bin/env bash
# Shared fixtures for comments tests.

# Run a repo task through mise so tests exercise the real task path.
comments() {
  cd "$REPO_DIR" && mise run -q "$@"
}
export -f comments
