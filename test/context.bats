#!/usr/bin/env bats

load test_helper

sample_context_json() {
  jq -n \
    --arg file "$BATS_TEST_TMPDIR/sample.md" \
    '{
      file: $file,
      directive: {
        range: {
          start: {line: 1, column: 0},
          end: {line: 1, column: 17},
          byteOffset: {start: 7, end: 24}
        },
        flags: "o",
        flag_list: ["o"],
        script: "script"
      }
    }'
}

@test "context fails clearly outside directive dispatch" {
  run comments context
  [ "$status" -ne 0 ]
  [[ "$output" == *"COMMENTS_CONTEXT_JSON is not set"* ]]
}

@test "context prints directive location by default" {
  COMMENTS_CONTEXT_JSON="$(sample_context_json)" run comments context
  [ "$status" -eq 0 ]
  [ "$output" = "$BATS_TEST_TMPDIR/sample.md:2" ]
}

@test "context --json prints public context" {
  COMMENTS_CONTEXT_JSON="$(sample_context_json)" run comments context --json
  [ "$status" -eq 0 ]
  [ "$(printf '%s\n' "$output" | jq -r '.file')" = "$BATS_TEST_TMPDIR/sample.md" ]
  [ "$(printf '%s\n' "$output" | jq -r '.directive.script')" = "script" ]
}

@test "context prints selected scalar fields" {
  COMMENTS_CONTEXT_JSON="$(sample_context_json)" run comments context file
  [ "$status" -eq 0 ]
  [ "$output" = "$BATS_TEST_TMPDIR/sample.md" ]

  COMMENTS_CONTEXT_JSON="$(sample_context_json)" run comments context line
  [ "$status" -eq 0 ]
  [ "$output" = "2" ]

  COMMENTS_CONTEXT_JSON="$(sample_context_json)" run comments context script
  [ "$status" -eq 0 ]
  [ "$output" = "script" ]
}

@test "context directive --json prints public directive record" {
  COMMENTS_CONTEXT_JSON="$(sample_context_json)" run comments context directive --json
  [ "$status" -eq 0 ]
  [ "$(printf '%s\n' "$output" | jq -r '.script')" = "script" ]
  [ "$(printf '%s\n' "$output" | jq -r '.range.start.line')" = "1" ]
}

@test "context rejects unknown fields" {
  COMMENTS_CONTEXT_JSON="$(sample_context_json)" run comments context nope
  [ "$status" -ne 0 ]
  [[ "$output" == *"unknown context field: nope"* ]]
}

@test "dispatch exposes stable context JSON to nested commands" {
  cat > "$BATS_TEST_TMPDIR/sample.md" <<'EOF'
<!--
o!
let ctx = ($env.COMMENTS_CONTEXT_JSON | from json)
$"file=($ctx.file | path basename) line=($ctx.directive.range.start.line + 1)"
-->
EOF

  COMMENTS_CALLER_PWD="$BATS_TEST_TMPDIR" run comments dispatch sample.md
  [ "$status" -eq 0 ]
  [ "$(cat "$BATS_TEST_TMPDIR/sample.md")" = "file=sample.md line=1" ]
}

@test "dispatch snippets can call comments context through PATH" {
  cat > "$BATS_TEST_TMPDIR/sample.md" <<'EOF'
before
<!-- o!(comments context) -->
after
EOF

  COMMENTS_CALLER_PWD="$BATS_TEST_TMPDIR" run comments dispatch sample.md
  [ "$status" -eq 0 ]
  printf -v expected 'before\n%s/sample.md:2\nafter' "$BATS_TEST_TMPDIR"
  [ "$(cat "$BATS_TEST_TMPDIR/sample.md")" = "$expected" ]
}
