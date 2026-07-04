#!/usr/bin/env bats

load test_helper

sample_context_json() {
  jq -n \
    --arg file "$BATS_TEST_TMPDIR/sample.md" \
    --arg target_dir "$BATS_TEST_TMPDIR" \
    --arg caller_pwd "$BATS_TEST_TMPDIR/caller" \
    '{
      file: $file,
      target_dir: $target_dir,
      caller_pwd: $caller_pwd,
      lines: ["before", "<!-- o!script -->", "after"],
      directive: {
        file: $file,
        kind: "html_block",
        range: {
          start: {line: 1, column: 0},
          end: {line: 1, column: 17},
          byteOffset: {start: 7, end: 24}
        },
        text: "<!-- o!script -->",
        body: "o!script",
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

@test "context --json prints full context" {
  COMMENTS_CONTEXT_JSON="$(sample_context_json)" run comments context --json
  [ "$status" -eq 0 ]
  [ "$(printf '%s\n' "$output" | jq -r '.file')" = "$BATS_TEST_TMPDIR/sample.md" ]
  [ "$(printf '%s\n' "$output" | jq -r '.directive.body')" = "o!script" ]
}

@test "context prints selected scalar fields" {
  COMMENTS_CONTEXT_JSON="$(sample_context_json)" run comments context file
  [ "$status" -eq 0 ]
  [ "$output" = "$BATS_TEST_TMPDIR/sample.md" ]

  COMMENTS_CONTEXT_JSON="$(sample_context_json)" run comments context line
  [ "$status" -eq 0 ]
  [ "$output" = "2" ]

  COMMENTS_CONTEXT_JSON="$(sample_context_json)" run comments context body
  [ "$status" -eq 0 ]
  [ "$output" = "o!script" ]
}

@test "context directive --json prints directive record" {
  COMMENTS_CONTEXT_JSON="$(sample_context_json)" run comments context directive --json
  [ "$status" -eq 0 ]
  [ "$(printf '%s\n' "$output" | jq -r '.text')" = "<!-- o!script -->" ]
  [ "$(printf '%s\n' "$output" | jq -r '.range.start.line')" = "1" ]
}

@test "context rejects unknown fields" {
  COMMENTS_CONTEXT_JSON="$(sample_context_json)" run comments context nope
  [ "$status" -ne 0 ]
  [[ "$output" == *"unknown context field: nope"* ]]
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
