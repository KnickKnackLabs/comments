#!/usr/bin/env bats

load test_helper

@test "directives parses no-flag JavaScript line comment" {
  cat > "$BATS_TEST_TMPDIR/sample.js" <<'EOF'
// !chat send "hello"
console.log('x')
EOF

  COMMENTS_CALLER_PWD="$BATS_TEST_TMPDIR" run comments directives sample.js
  [ "$status" -eq 0 ]
  [ "$(printf '%s\n' "$output" | jq -r '.flags')" = "" ]
  [ "$(printf '%s\n' "$output" | jq -r '.script')" = "chat send \"hello\"" ]
  [ "$(printf '%s\n' "$output" | jq -r '.body')" = "!chat send \"hello\"" ]
}

@test "directives parses flagged block comments" {
  cat > "$BATS_TEST_TMPDIR/sample.js" <<'EOF'
/*
oi!curl https://example.com
*/
console.log('x')
EOF

  COMMENTS_CALLER_PWD="$BATS_TEST_TMPDIR" run comments directives sample.js
  [ "$status" -eq 0 ]
  [ "$(printf '%s\n' "$output" | jq -r '.flags')" = "oi" ]
  [ "$(printf '%s\n' "$output" | jq -r '.flag_list | join(",")')" = "o,i" ]
  [ "$(printf '%s\n' "$output" | jq -r '.script')" = "curl https://example.com" ]
}

@test "directives parses single-line Markdown HTML comments" {
  cat > "$BATS_TEST_TMPDIR/sample.md" <<'EOF'
<!-- o!echo "hello" -->
EOF

  COMMENTS_CALLER_PWD="$BATS_TEST_TMPDIR" run comments directives sample.md
  [ "$status" -eq 0 ]
  [ "$(printf '%s\n' "$output" | jq -r '.flags')" = "o" ]
  [ "$(printf '%s\n' "$output" | jq -r '.script')" = "echo \"hello\"" ]
}

@test "directives parses multiline Markdown HTML comments" {
  cat > "$BATS_TEST_TMPDIR/sample.md" <<'EOF'
# Title

<!--
!chat send "hello"
-->
EOF

  COMMENTS_CALLER_PWD="$BATS_TEST_TMPDIR" run comments directives sample.md
  [ "$status" -eq 0 ]
  [ "$(printf '%s\n' "$output" | jq -r '.kind')" = "html_block" ]
  [ "$(printf '%s\n' "$output" | jq -r '.script')" = "chat send \"hello\"" ]
  [ "$(printf '%s\n' "$output" | jq -r '.range.start.line')" = "2" ]
}

@test "directives ignores ordinary comments" {
  cat > "$BATS_TEST_TMPDIR/sample.js" <<'EOF'
// ordinary comment
console.log('x')
EOF

  COMMENTS_CALLER_PWD="$BATS_TEST_TMPDIR" run comments directives sample.js
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "directives preserves extraction errors" {
  COMMENTS_CALLER_PWD="$BATS_TEST_TMPDIR" run comments directives missing.md
  [ "$status" -ne 0 ]
  [[ "$output" == *"file not found"* ]]
}

@test "directives preserves multiline scripts from block comments" {
  cat > "$BATS_TEST_TMPDIR/sample.js" <<'EOF_JS'
/*
!let name = "Or"
$"hello ($name)"
*/
EOF_JS

  COMMENTS_CALLER_PWD="$BATS_TEST_TMPDIR" run comments directives sample.js
  [ "$status" -eq 0 ]
  expected=$'let name = "Or"\n$"hello ($name)"'
  [ "$(printf '%s\n' "$output" | jq -r '.script')" = "$expected" ]
}

@test "directives preserves multiline scripts from Markdown comments" {
  cat > "$BATS_TEST_TMPDIR/sample.md" <<'EOF_MD'
<!--
o!let rows = [1 2 3]
$rows | length
-->
EOF_MD

  COMMENTS_CALLER_PWD="$BATS_TEST_TMPDIR" run comments directives sample.md
  [ "$status" -eq 0 ]
  [ "$(printf '%s\n' "$output" | jq -r '.flags')" = "o" ]
  expected=$'let rows = [1 2 3]\n$rows | length'
  [ "$(printf '%s\n' "$output" | jq -r '.script')" = "$expected" ]
}
