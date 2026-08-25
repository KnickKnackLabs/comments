#!/usr/bin/env bats

bats_require_minimum_version 1.5.0

load test_helper

setup() {
  MOCK_DIR="$BATS_TEST_TMPDIR/test-runner-bin"
  BATS_LOG="$BATS_TEST_TMPDIR/bats.log"
  mkdir -p "$MOCK_DIR"
  export BATS_LOG

  cat > "$MOCK_DIR/bats" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
{
  printf 'jobs=%s\n' "${BATS_NUMBER_OF_PARALLEL_JOBS:-}"
  printf 'runner=%s\n' "${BATS_PARALLEL_BINARY_NAME:-}"
  for argument in "$@"; do
    printf 'arg=%s\n' "$argument"
  done
} > "$BATS_LOG"
SH

  cat > "$MOCK_DIR/rush" <<'SH'
#!/usr/bin/env bash
exit 0
SH

  chmod +x "$MOCK_DIR/bats" "$MOCK_DIR/rush"
  export BATS_COMMAND="$MOCK_DIR/bats"
  export RUSH_COMMAND="$MOCK_DIR/rush"
  unset BATS_NUMBER_OF_PARALLEL_JOBS BATS_PARALLEL_BINARY_NAME
}

log_value() {
  local key="$1"
  awk -F= -v key="$key" '$1 == key { print substr($0, length(key) + 2); exit }' "$BATS_LOG"
}

arg_count() {
  local expected="$1"
  awk -F= -v expected="$expected" '$1 == "arg" && substr($0, 5) == expected { count++ } END { print count + 0 }' "$BATS_LOG"
}

expected_across_fallback_count() {
  case "$REPO_DIR" in
    *[[:space:]]*) printf '1\n' ;;
    *) printf '0\n' ;;
  esac
}

@test "test task defaults to four Rush jobs without disabling within-file concurrency" {
  run comments test skeleton --filter standard
  [ "$status" -eq 0 ]
  [[ "$output" == *"4 jobs via"* ]]
  [ "$(log_value jobs)" = "4" ]
  [ "$(log_value runner)" = "$MOCK_DIR/rush" ]
  [ "$(arg_count --no-parallelize-across-files)" -eq "$(expected_across_fallback_count)" ]
  [ "$(arg_count --no-parallelize-within-files)" -eq 0 ]
  [ "$(arg_count "$REPO_DIR/test/skeleton.bats")" -eq 1 ]
}

@test "explicit serial execution does not require Rush" {
  export RUSH_COMMAND="$MOCK_DIR/missing-rush"

  run comments test --jobs 1 skeleton
  [ "$status" -eq 0 ]
  [[ "$output" == *"BATS parallelism: serial"* ]]
  [ "$(arg_count --no-parallelize-across-files)" -eq 0 ]
  [ "$(arg_count --no-parallelize-within-files)" -eq 0 ]
}

@test "parallel whitespace arguments use only the across-file fallback" {
  run comments test skeleton --filter "standard behavior"
  [ "$status" -eq 0 ]
  [ "$(arg_count --no-parallelize-across-files)" -eq 1 ]
  [ "$(arg_count --no-parallelize-within-files)" -eq 0 ]
  [ "$(arg_count --filter)" -eq 1 ]
  [ "$(arg_count "standard behavior")" -eq 1 ]
}

@test "serial whitespace targets do not require a parallel backend" {
  target="$BATS_TEST_TMPDIR/serial target/fixture file.bats"
  mkdir -p "$(dirname "$target")"
  printf '%s\n' '#!/usr/bin/env bats' > "$target"
  export RUSH_COMMAND="$MOCK_DIR/missing-rush"

  run comments test "$target" --jobs 1
  [ "$status" -eq 0 ]
  [ "$(arg_count "$target")" -eq 1 ]
  [ "$(arg_count --no-parallelize-across-files)" -eq 0 ]
}

@test "parallel execution fails clearly without the selected runner" {
  export RUSH_COMMAND="$MOCK_DIR/missing-rush"

  run -127 comments test skeleton
  [ "$status" -eq 127 ]
  [[ "$output" == *"parallel runner '$MOCK_DIR/missing-rush' is unavailable for 4 jobs"* ]]
  [ ! -e "$BATS_LOG" ]
}

@test "invalid job count fails before BATS" {
  export BATS_NUMBER_OF_PARALLEL_JOBS=lots

  run -2 comments test skeleton
  [ "$status" -eq 2 ]
  [[ "$output" == *"must be a positive integer"* ]]
  [ ! -e "$BATS_LOG" ]
}

@test "whitespace fallback retains public within-file concurrency" {
  probe_dir="$BATS_TEST_TMPDIR/within file probe"
  export PROBE_DIR="$BATS_TEST_TMPDIR/within-file-barrier"
  mkdir -p "$probe_dir" "$PROBE_DIR"

  test_keyword='@test'
  {
    printf '%s\n' '#!/usr/bin/env bats'
    printf '%s\n' "$test_keyword \"first test observes second test\" {"
    cat <<'BATS'
  touch "$PROBE_DIR/one"
  for _ in {1..50}; do
    [ ! -e "$PROBE_DIR/two" ] || return 0
    sleep 0.05
  done
  false
}
BATS
    printf '%s\n' "$test_keyword \"second test observes first test\" {"
    cat <<'BATS'
  touch "$PROBE_DIR/two"
  for _ in {1..50}; do
    [ ! -e "$PROBE_DIR/one" ] || return 0
    sleep 0.05
  done
  false
}
BATS
  } > "$probe_dir/within-file.bats"

  unset BATS_COMMAND RUSH_COMMAND
  unset BATS_NUMBER_OF_PARALLEL_JOBS BATS_PARALLEL_BINARY_NAME

  run comments test "$probe_dir"

  [ "$status" -eq 0 ]
  [[ "$output" == *"4 jobs via"* ]]
}

@test "normal parallel paths retain across-file scheduling" {
  case "$REPO_DIR" in
    *[[:space:]]*) skip "config-root fallback intentionally serializes files" ;;
  esac

  probe_dir="$BATS_TEST_TMPDIR/across-file-probe"
  export PROBE_DIR="$BATS_TEST_TMPDIR/across-file-barrier"
  mkdir -p "$probe_dir" "$PROBE_DIR"

  test_keyword='@test'
  {
    printf '%s\n' '#!/usr/bin/env bats'
    printf '%s\n' "$test_keyword \"first file observes second file\" {"
    cat <<'BATS'
  touch "$PROBE_DIR/one"
  for _ in {1..50}; do
    [ ! -e "$PROBE_DIR/two" ] || return 0
    sleep 0.05
  done
  false
}
BATS
  } > "$probe_dir/first.bats"
  {
    printf '%s\n' '#!/usr/bin/env bats'
    printf '%s\n' "$test_keyword \"second file observes first file\" {"
    cat <<'BATS'
  touch "$PROBE_DIR/two"
  for _ in {1..50}; do
    [ ! -e "$PROBE_DIR/one" ] || return 0
    sleep 0.05
  done
  false
}
BATS
  } > "$probe_dir/second.bats"

  unset BATS_COMMAND RUSH_COMMAND
  unset BATS_NUMBER_OF_PARALLEL_JOBS BATS_PARALLEL_BINARY_NAME

  run comments test "$probe_dir"

  [ "$status" -eq 0 ]
  [[ "$output" == *"4 jobs via"* ]]
}
