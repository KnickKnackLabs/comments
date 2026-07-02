#!/usr/bin/env bats

load test_helper

@test "standard comments surfaces exist" {
  for path in \
    mise.toml \
    README.tsx \
    README.md \
    CONTRIBUTING.md \
    .mise/tasks/test \
    .mise/tasks/doctor \
    .github/workflows/test.yml \
    lib/.gitkeep
  do
    [ -e "$REPO_DIR/$path" ]
  done
}

@test "README.md is generated from README.tsx" {
  run bash -c 'cd "$REPO_DIR" && readme build --check'
  [ "$status" -eq 0 ]
}

@test "doctor reports optional pre-commit hook state" {
  run comments doctor
  [ "$status" -eq 0 ]
  [[ "$output" == *"pre-commit"* ]]
}


@test "runtime tools are available" {
  run bash -c 'command -v ast-grep && command -v nu && command -v jq'
  [ "$status" -eq 0 ]
}
