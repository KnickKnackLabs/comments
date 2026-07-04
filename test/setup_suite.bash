setup_suite() {
  REPO_DIR="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  export REPO_DIR

  bats_libexec="${BATS_LIBEXEC:-}"
  eval "$(cd "$REPO_DIR" && mise env)"
  TEST_BIN="$(mktemp -d)"
  export TEST_BIN
  cat > "$TEST_BIN/comments" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
cd "$REPO_DIR"
exec mise run -q "$@"
EOF
  chmod +x "$TEST_BIN/comments"
  export PATH="$TEST_BIN:$PATH"
  if [ -n "$bats_libexec" ]; then
    export PATH="$bats_libexec:$PATH"
  fi
}

teardown_suite() {
  if [ -n "${TEST_BIN:-}" ]; then
    rm -rf "$TEST_BIN"
  fi
}
