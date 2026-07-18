#!/usr/bin/env bats

load test_helper

zed_default_spawn_key() {
  case "$(uname -s)" in
    Darwin) printf 'cmd-shift-d' ;;
    *) printf 'ctrl-shift-d' ;;
  esac
}

zed_default_rerun_key() {
  case "$(uname -s)" in
    Darwin) printf 'cmd-shift-r' ;;
    *) printf 'ctrl-shift-r' ;;
  esac
}

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

@test "integrations:zed --stdout includes requested review task fields" {
  run comments integrations:zed \
    --stdout \
    --reveal never \
    --shell-program /bin/zsh \
    --shell-arg=-f \
    --env COMMENT_CHAT_AS=or \
    --env 'REVIEW_LABEL=hello world'
  [ "$status" -eq 0 ]

  [ "$(printf '%s\n' "$output" | jq -r '.[0].reveal')" = "never" ]
  [ "$(printf '%s\n' "$output" | jq -r '.[0].shell.with_arguments.program')" = "/bin/zsh" ]
  [ "$(printf '%s\n' "$output" | jq -r '.[0].shell.with_arguments.args[0]')" = "-f" ]
  [ "$(printf '%s\n' "$output" | jq -r '.[0].env.COMMENT_CHAT_AS')" = "or" ]
  [ "$(printf '%s\n' "$output" | jq -r '.[0].env.REVIEW_LABEL')" = "hello world" ]
}

@test "integrations:zed installs and replaces requested review task fields" {
  COMMENTS_CALLER_PWD="$BATS_TEST_TMPDIR" run comments integrations:zed \
    --reveal never \
    --shell-program /bin/zsh \
    --shell-arg=-f \
    --env COMMENT_CHAT_AS=or
  [ "$status" -eq 0 ]

  tasks="$BATS_TEST_TMPDIR/.zed/tasks.json"
  [ "$(jq 'length' "$tasks")" = "1" ]
  [ "$(jq -r '.[0].reveal' "$tasks")" = "never" ]
  [ "$(jq -r '.[0].shell.with_arguments.program' "$tasks")" = "/bin/zsh" ]
  [ "$(jq -r '.[0].shell.with_arguments.args[0]' "$tasks")" = "-f" ]
  [ "$(jq -r '.[0].env.COMMENT_CHAT_AS' "$tasks")" = "or" ]

  COMMENTS_CALLER_PWD="$BATS_TEST_TMPDIR" run comments integrations:zed --reveal no_focus
  [ "$status" -eq 0 ]
  [ "$(jq 'length' "$tasks")" = "1" ]
  [ "$(jq -r '.[0].reveal' "$tasks")" = "no_focus" ]
  [ "$(jq -r '.[0] | has("shell")' "$tasks")" = "false" ]
  [ "$(jq -r '.[0] | has("env")' "$tasks")" = "false" ]
}

@test "integrations:zed validates review task fields before any writes" {
  ZED_CONFIG_HOME="$BATS_TEST_TMPDIR/zed-config" COMMENTS_CALLER_PWD="$BATS_TEST_TMPDIR" run comments integrations:zed \
    --keymap \
    --reveal sometimes
  [ "$status" -ne 0 ]
  [[ "$output" == *"invalid reveal value: sometimes"* ]]
  [ ! -e "$BATS_TEST_TMPDIR/.zed/tasks.json" ]
  [ ! -e "$BATS_TEST_TMPDIR/zed-config/keymap.json" ]

  COMMENTS_CALLER_PWD="$BATS_TEST_TMPDIR" run comments integrations:zed --shell-arg=-f
  [ "$status" -ne 0 ]
  [[ "$output" == *"--shell-arg requires --shell-program"* ]]
  [ ! -e "$BATS_TEST_TMPDIR/.zed/tasks.json" ]
}

@test "integrations:zed creates only .zed/tasks.json by default" {
  ZED_CONFIG_HOME="$BATS_TEST_TMPDIR/zed-config" COMMENTS_CALLER_PWD="$BATS_TEST_TMPDIR" run comments integrations:zed
  [ "$status" -eq 0 ]
  [[ "$output" == *".zed/tasks.json"* ]]
  [[ "$output" != *"keymap.json"* ]]

  tasks="$BATS_TEST_TMPDIR/.zed/tasks.json"
  [ -f "$tasks" ]
  [ "$(jq -r '.[0].label' "$tasks")" = "comments: dispatch current file" ]
  [ "$(jq -r '.[0].args[1]' "$tasks")" = '$ZED_FILE' ]
  [ ! -e "$BATS_TEST_TMPDIR/zed-config/keymap.json" ]
}

@test "integrations:zed --keymap creates task and keymap wiring" {
  ZED_CONFIG_HOME="$BATS_TEST_TMPDIR/zed-config" COMMENTS_CALLER_PWD="$BATS_TEST_TMPDIR" run comments integrations:zed --keymap
  [ "$status" -eq 0 ]
  [[ "$output" == *".zed/tasks.json"* ]]
  [[ "$output" == *"keymap.json"* ]]

  keymap="$BATS_TEST_TMPDIR/zed-config/keymap.json"
  spawn_key="$(zed_default_spawn_key)"
  rerun_key="$(zed_default_rerun_key)"

  [ "$(jq -r --arg key "$spawn_key" '.[0].bindings[$key][0]' "$keymap")" = "task::Spawn" ]
  [ "$(jq -r --arg key "$spawn_key" '.[0].bindings[$key][1].task_name' "$keymap")" = "comments: dispatch current file" ]
  [ "$(jq -r --arg key "$rerun_key" '.[0].bindings[$key][0]' "$keymap")" = "task::Rerun" ]
  [ "$(jq -r --arg key "$rerun_key" '.[0].bindings[$key][1].reevaluate_context' "$keymap")" = "true" ]
}

@test "integrations:zed --keymap supports custom keybindings" {
  ZED_CONFIG_HOME="$BATS_TEST_TMPDIR/zed-config" COMMENTS_CALLER_PWD="$BATS_TEST_TMPDIR" run comments integrations:zed \
    --keymap \
    --keystroke alt-d \
    --rerun-keystroke alt-r
  [ "$status" -eq 0 ]

  keymap="$BATS_TEST_TMPDIR/zed-config/keymap.json"
  [ "$(jq -r '.[0].bindings["alt-d"][0]' "$keymap")" = "task::Spawn" ]
  [ "$(jq -r '.[0].bindings["alt-r"][0]' "$keymap")" = "task::Rerun" ]
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

  ZED_CONFIG_HOME="$BATS_TEST_TMPDIR/zed-config" COMMENTS_CALLER_PWD="$BATS_TEST_TMPDIR" run comments integrations:zed
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

  ZED_CONFIG_HOME="$BATS_TEST_TMPDIR/zed-config" COMMENTS_CALLER_PWD="$BATS_TEST_TMPDIR" run comments integrations:zed
  [ "$status" -eq 0 ]

  tasks="$BATS_TEST_TMPDIR/.zed/tasks.json"
  [ "$(jq 'length' "$tasks")" = "1" ]
  [ "$(jq -r '.[0].command' "$tasks")" = "comments" ]
  [ "$(jq -r '.[0].args[0]' "$tasks")" = "dispatch" ]
}

@test "integrations:zed fails without clobbering non-array tasks.json" {
  mkdir -p "$BATS_TEST_TMPDIR/.zed"
  printf '{"label":"not an array"}\n' > "$BATS_TEST_TMPDIR/.zed/tasks.json"

  ZED_CONFIG_HOME="$BATS_TEST_TMPDIR/zed-config" COMMENTS_CALLER_PWD="$BATS_TEST_TMPDIR" run comments integrations:zed --keymap
  [ "$status" -ne 0 ]
  [[ "$output" == *"must be a JSON array"* ]]
  [ "$(cat "$BATS_TEST_TMPDIR/.zed/tasks.json")" = '{"label":"not an array"}' ]
  [ ! -e "$BATS_TEST_TMPDIR/zed-config/keymap.json" ]
}

@test "integrations:zed --keymap fails without clobbering conflicting keymap binding" {
  mkdir -p "$BATS_TEST_TMPDIR/zed-config"
  spawn_key="$(zed_default_spawn_key)"
  jq -n --arg key "$spawn_key" '[{"context":"Workspace","bindings":{($key):"workspace::Open"}}]' > "$BATS_TEST_TMPDIR/zed-config/keymap.json"

  ZED_CONFIG_HOME="$BATS_TEST_TMPDIR/zed-config" COMMENTS_CALLER_PWD="$BATS_TEST_TMPDIR" run comments integrations:zed --keymap
  [ "$status" -ne 0 ]
  [[ "$output" == *"already exists with a different value"* ]]
  [ "$(jq -r --arg key "$spawn_key" '.[0].bindings[$key]' "$BATS_TEST_TMPDIR/zed-config/keymap.json")" = "workspace::Open" ]
  [ ! -e "$BATS_TEST_TMPDIR/.zed/tasks.json" ]
}

@test "integrations:zed --keymap-force replaces conflicting keymap binding" {
  mkdir -p "$BATS_TEST_TMPDIR/zed-config"
  spawn_key="$(zed_default_spawn_key)"
  jq -n --arg key "$spawn_key" '[{"context":"Workspace","bindings":{($key):"workspace::Open"}}]' > "$BATS_TEST_TMPDIR/zed-config/keymap.json"

  ZED_CONFIG_HOME="$BATS_TEST_TMPDIR/zed-config" COMMENTS_CALLER_PWD="$BATS_TEST_TMPDIR" run comments integrations:zed --keymap-force
  [ "$status" -eq 0 ]
  [ "$(jq -r --arg key "$spawn_key" '.[0].bindings[$key][0]' "$BATS_TEST_TMPDIR/zed-config/keymap.json")" = "task::Spawn" ]
}
