#!/usr/bin/env bats

load test_helper

@test "dispatch exits zero with no output when file has no directives" {
  cat > "$BATS_TEST_TMPDIR/sample.md" <<'EOF'
# Title

ordinary text
EOF

  COMMENTS_CALLER_PWD="$BATS_TEST_TMPDIR" run comments dispatch sample.md
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "dispatch consumes a single non-output directive" {
  cat > "$BATS_TEST_TMPDIR/sample.md" <<'EOF'
before
<!-- !$"hello" -->
after
EOF

  COMMENTS_CALLER_PWD="$BATS_TEST_TMPDIR" run comments dispatch sample.md
  [ "$status" -eq 0 ]
  [ -z "$output" ]
  expected=$'before\nafter'
  [ "$(cat "$BATS_TEST_TMPDIR/sample.md")" = "$expected" ]
}

@test "dispatch consumes multiple non-output directives" {
  cat > "$BATS_TEST_TMPDIR/sample.md" <<'EOF'
<!-- !$"first" -->
middle
<!-- !$"second" -->
EOF

  COMMENTS_CALLER_PWD="$BATS_TEST_TMPDIR" run comments dispatch sample.md
  [ "$status" -eq 0 ]
  [ -z "$output" ]
  [ "$(cat "$BATS_TEST_TMPDIR/sample.md")" = "middle" ]
}

@test "dispatch provides context to directive scripts" {
  cat > "$BATS_TEST_TMPDIR/sample.md" <<'EOF'
# Title

<!-- o!$"file=($context.file | path basename) line=($context.directive.range.start.line) lines=($context.lines | length)" -->
EOF

  COMMENTS_CALLER_PWD="$BATS_TEST_TMPDIR" run comments dispatch sample.md
  [ "$status" -eq 0 ]
  [ -z "$output" ]
  expected=$'# Title\n\nfile=sample.md line=2 lines=3'
  [ "$(cat "$BATS_TEST_TMPDIR/sample.md")" = "$expected" ]
}

@test "dispatch supports multiline directive scripts" {
  cat > "$BATS_TEST_TMPDIR/sample.md" <<'EOF'
<!--
o!
let rows = [1 2 3]
$rows | length
-->
EOF

  COMMENTS_CALLER_PWD="$BATS_TEST_TMPDIR" run comments dispatch sample.md
  [ "$status" -eq 0 ]
  [ -z "$output" ]
  [ "$(cat "$BATS_TEST_TMPDIR/sample.md")" = "3" ]
}

@test "dispatch replaces output directives with stdout" {
  cat > "$BATS_TEST_TMPDIR/sample.md" <<'EOF'
before
<!-- o!$"hello" -->
after
EOF

  COMMENTS_CALLER_PWD="$BATS_TEST_TMPDIR" run comments dispatch sample.md
  [ "$status" -eq 0 ]
  [ -z "$output" ]
  expected=$'before\nhello\nafter'
  [ "$(cat "$BATS_TEST_TMPDIR/sample.md")" = "$expected" ]
}

@test "dispatch replaces multiline output directive comments" {
  cat > "$BATS_TEST_TMPDIR/sample.md" <<'EOF'
before
<!--
o!
let rows = [1 2 3]
$rows | length
-->
after
EOF

  COMMENTS_CALLER_PWD="$BATS_TEST_TMPDIR" run comments dispatch sample.md
  [ "$status" -eq 0 ]
  expected=$'before\n3\nafter'
  [ "$(cat "$BATS_TEST_TMPDIR/sample.md")" = "$expected" ]
}

@test "dispatch applies multiple output replacements by original byte ranges" {
  cat > "$BATS_TEST_TMPDIR/sample.md" <<'EOF'
<!-- o!$"first" -->
middle
<!-- o!$"second" -->
EOF

  COMMENTS_CALLER_PWD="$BATS_TEST_TMPDIR" run comments dispatch sample.md
  [ "$status" -eq 0 ]
  expected=$'first\nmiddle\nsecond'
  [ "$(cat "$BATS_TEST_TMPDIR/sample.md")" = "$expected" ]
}

@test "dispatch leaves failing output directives unchanged" {
  cat > "$BATS_TEST_TMPDIR/sample.md" <<'EOF'
before
<!-- o!exit 7 -->
after
EOF
  original="$(cat "$BATS_TEST_TMPDIR/sample.md")"

  COMMENTS_CALLER_PWD="$BATS_TEST_TMPDIR" run comments dispatch sample.md
  [ "$status" -eq 7 ]
  [ "$(cat "$BATS_TEST_TMPDIR/sample.md")" = "$original" ]
}

@test "dispatch applies successful output replacements even when another directive fails" {
  cat > "$BATS_TEST_TMPDIR/sample.md" <<'EOF'
<!-- o!$"first" -->
<!-- o!exit 7 -->
<!-- o!$"third" -->
EOF

  COMMENTS_CALLER_PWD="$BATS_TEST_TMPDIR" run comments dispatch sample.md
  [ "$status" -eq 7 ]
  expected=$'first\n<!-- o!exit 7 -->\nthird'
  [ "$(cat "$BATS_TEST_TMPDIR/sample.md")" = "$expected" ]
}

@test "dispatch continues after unsupported flags and applies other successful replacements" {
  cat > "$BATS_TEST_TMPDIR/sample.md" <<'EOF'
<!-- o!$"first" -->
<!-- i!$"unsupported" -->
<!-- o!$"third" -->
EOF

  COMMENTS_CALLER_PWD="$BATS_TEST_TMPDIR" run comments dispatch sample.md
  [ "$status" -ne 0 ]
  [[ "$output" == *"unsupported directive flags: i"* ]]
  expected=$'first\n<!-- i!$"unsupported" -->\nthird'
  [ "$(cat "$BATS_TEST_TMPDIR/sample.md")" = "$expected" ]
}

@test "dispatch rejects unsupported non-output flags" {
  cat > "$BATS_TEST_TMPDIR/sample.md" <<'EOF'
<!-- i!$"hello" -->
EOF

  COMMENTS_CALLER_PWD="$BATS_TEST_TMPDIR" run comments dispatch sample.md
  [ "$status" -ne 0 ]
  [[ "$output" == *"unsupported directive flags: i"* ]]
}

@test "dispatch propagates directive failures" {
  cat > "$BATS_TEST_TMPDIR/sample.md" <<'EOF'
<!-- !exit 7 -->
EOF

  COMMENTS_CALLER_PWD="$BATS_TEST_TMPDIR" run comments dispatch sample.md
  [ "$status" -eq 7 ]
}

@test "dispatch exits nonzero for missing files" {
  COMMENTS_CALLER_PWD="$BATS_TEST_TMPDIR" run comments dispatch missing.md
  [ "$status" -ne 0 ]
  [[ "$output" == *"file not found"* ]]
}
