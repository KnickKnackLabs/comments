#!/usr/bin/env bats

load test_helper

@test "resolve-target preserves absolute paths" {
  run comments_nu 'use ./lib/comments/extract.nu resolve-target; resolve-target "/tmp/file.md" "/repo"'
  [ "$status" -eq 0 ]
  [ "$output" = "/tmp/file.md" ]
}

@test "resolve-target joins relative paths to base" {
  run comments_nu 'use ./lib/comments/extract.nu resolve-target; resolve-target "notes/file.md" "/repo"'
  [ "$status" -eq 0 ]
  [ "$output" = "/repo/notes/file.md" ]
}

@test "resolve-target preserves dot segments for filesystem lookup" {
  run comments_nu 'use ./lib/comments/extract.nu resolve-target; resolve-target "./file.md" "/repo"'
  [ "$status" -eq 0 ]
  [ "$output" = "/repo/file.md" ]
}
