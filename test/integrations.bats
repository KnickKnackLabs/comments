#!/usr/bin/env bats

load test_helper

@test "integrations:zed --stdout prints a valid current-file task snippet" {
  run comments integrations:zed --stdout
  [ "$status" -eq 0 ]

  [ "$(printf '%s\n' "$output" | jq -r '.[0].label')" = "comments: dispatch current file" ]
  [ "$(printf '%s\n' "$output" | jq -r '.[0].command')" = "comments" ]
  [ "$(printf '%s\n' "$output" | jq -r '.[0].args[0]')" = "dispatch" ]
  [ "$(printf '%s\n' "$output" | jq -r '.[0].args[1]')" = '$ZED_FILE' ]
  [ "$(printf '%s\n' "$output" | jq -r '.[0].save')" = "current" ]
  [ "$(printf '%s\n' "$output" | jq -r '.[0].hide')" = "on_success" ]
}

@test "integrations:zed creates .zed/tasks.json in the caller directory" {
  COMMENTS_CALLER_PWD="$BATS_TEST_TMPDIR" run comments integrations:zed
  [ "$status" -eq 0 ]
  [[ "$output" == *".zed/tasks.json"* ]]

  tasks="$BATS_TEST_TMPDIR/.zed/tasks.json"
  [ -f "$tasks" ]
  [ "$(jq -r '.[0].label' "$tasks")" = "comments: dispatch current file" ]
  [ "$(jq -r '.[0].args[1]' "$tasks")" = '$ZED_FILE' ]
}

@test "integrations:zed appends to existing Zed tasks" {
  mkdir -p "$BATS_TEST_TMPDIR/.zed"
  cat > "$BATS_TEST_TMPDIR/.zed/tasks.json" <<'JSON'
[
  {
    "label": "existing task",
    "command": "echo",
    "args": ["hello"]
  }
]
JSON

  COMMENTS_CALLER_PWD="$BATS_TEST_TMPDIR" run comments integrations:zed
  [ "$status" -eq 0 ]

  tasks="$BATS_TEST_TMPDIR/.zed/tasks.json"
  [ "$(jq 'length' "$tasks")" = "2" ]
  [ "$(jq -r '.[0].label' "$tasks")" = "existing task" ]
  [ "$(jq -r '.[1].label' "$tasks")" = "comments: dispatch current file" ]
}

@test "integrations:zed updates existing comments task without duplicating" {
  mkdir -p "$BATS_TEST_TMPDIR/.zed"
  cat > "$BATS_TEST_TMPDIR/.zed/tasks.json" <<'JSON'
[
  {
    "label": "comments: dispatch current file",
    "command": "old-comments",
    "args": ["old"]
  }
]
JSON

  COMMENTS_CALLER_PWD="$BATS_TEST_TMPDIR" run comments integrations:zed
  [ "$status" -eq 0 ]

  tasks="$BATS_TEST_TMPDIR/.zed/tasks.json"
  [ "$(jq 'length' "$tasks")" = "1" ]
  [ "$(jq -r '.[0].command' "$tasks")" = "comments" ]
  [ "$(jq -r '.[0].args[0]' "$tasks")" = "dispatch" ]
}

@test "integrations:zed fails without clobbering non-array tasks.json" {
  mkdir -p "$BATS_TEST_TMPDIR/.zed"
  printf '{"label":"not an array"}\n' > "$BATS_TEST_TMPDIR/.zed/tasks.json"

  COMMENTS_CALLER_PWD="$BATS_TEST_TMPDIR" run comments integrations:zed
  [ "$status" -ne 0 ]
  [[ "$output" == *"must be a JSON array"* ]]
  [ "$(cat "$BATS_TEST_TMPDIR/.zed/tasks.json")" = '{"label":"not an array"}' ]
}
