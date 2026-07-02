#!/usr/bin/env bats

load test_helper

@test "extract returns JavaScript comments" {
  cat > "$BATS_TEST_TMPDIR/sample.js" <<'EOF'
// !chat hello
console.log('x')
EOF

  COMMENTS_CALLER_PWD="$BATS_TEST_TMPDIR" run comments extract sample.js
  [ "$status" -eq 0 ]
  [ "$(printf '%s\n' "$output" | jq -r '.kind')" = "comment" ]
  [[ "$(printf '%s\n' "$output" | jq -r '.text')" == "// !chat hello" ]]
}

@test "extract returns Rust line comments" {
  cat > "$BATS_TEST_TMPDIR/sample.rs" <<'EOF'
fn main() {
  // !chat hello
}
EOF

  COMMENTS_CALLER_PWD="$BATS_TEST_TMPDIR" run comments extract sample.rs
  [ "$status" -eq 0 ]
  [ "$(printf '%s\n' "$output" | jq -r '.kind')" = "line_comment" ]
  [[ "$(printf '%s\n' "$output" | jq -r '.text')" == "// !chat hello" ]]
}

@test "extract returns multiline Markdown HTML comments" {
  cat > "$BATS_TEST_TMPDIR/sample.md" <<'EOF'
# Title

<!--
!chat send "hello"
  multiline body
-->
EOF

  COMMENTS_CALLER_PWD="$BATS_TEST_TMPDIR" run comments extract sample.md
  [ "$status" -eq 0 ]
  [ "$(printf '%s\n' "$output" | jq -r '.kind')" = "html_block" ]
  printf '%s\n' "$output" | jq -e '.text | contains("multiline body")' >/dev/null
  [ "$(printf '%s\n' "$output" | jq -r '.range.start.line')" = "2" ]
}

@test "extract exits nonzero for missing files" {
  COMMENTS_CALLER_PWD="$BATS_TEST_TMPDIR" run comments extract missing.md
  [ "$status" -ne 0 ]
  [[ "$output" == *"file not found"* ]]
}
