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

@test "dispatch runs a single directive" {
  cat > "$BATS_TEST_TMPDIR/sample.md" <<'EOF'
<!-- !$"hello" -->
EOF

  COMMENTS_CALLER_PWD="$BATS_TEST_TMPDIR" run comments dispatch sample.md
  [ "$status" -eq 0 ]
  [ "$output" = "hello" ]
}

@test "dispatch runs directives in file order" {
  cat > "$BATS_TEST_TMPDIR/sample.md" <<'EOF'
<!-- !$"first" -->

<!-- !$"second" -->
EOF

  COMMENTS_CALLER_PWD="$BATS_TEST_TMPDIR" run comments dispatch sample.md
  [ "$status" -eq 0 ]
  expected=$'first\nsecond'
  [ "$output" = "$expected" ]
}

@test "dispatch provides context to directive scripts" {
  cat > "$BATS_TEST_TMPDIR/sample.md" <<'EOF'
# Title

<!-- !$"file=($context.file | path basename) line=($context.directive.range.start.line) lines=($context.lines | length)" -->
EOF

  COMMENTS_CALLER_PWD="$BATS_TEST_TMPDIR" run comments dispatch sample.md
  [ "$status" -eq 0 ]
  [ "$output" = "file=sample.md line=2 lines=3" ]
}

@test "dispatch supports multiline directive scripts" {
  cat > "$BATS_TEST_TMPDIR/sample.md" <<'EOF'
<!--
!
let rows = [1 2 3]
$rows | length
-->
EOF

  COMMENTS_CALLER_PWD="$BATS_TEST_TMPDIR" run comments dispatch sample.md
  [ "$status" -eq 0 ]
  [ "$output" = "3" ]
}

@test "dispatch rejects unsupported flags" {
  cat > "$BATS_TEST_TMPDIR/sample.md" <<'EOF'
<!-- o!$"hello" -->
EOF

  COMMENTS_CALLER_PWD="$BATS_TEST_TMPDIR" run comments dispatch sample.md
  [ "$status" -ne 0 ]
  [[ "$output" == *"unsupported directive flags: o"* ]]
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
