#!/usr/bin/env bats

load test_helper

@test "parse-directive parses no-flag directives" {
  run comments_nu 'use ./lib/comments/directives.nu parse-directive; parse-directive "!chat send hi" | to json -r'
  [ "$status" -eq 0 ]
  [ "$(printf '%s\n' "$output" | jq -r '.flags')" = "" ]
  [ "$(printf '%s\n' "$output" | jq -r '.flag_list | length')" = "0" ]
  [ "$(printf '%s\n' "$output" | jq -r '.script')" = "chat send hi" ]
}

@test "parse-directive parses one flag" {
  run comments_nu 'use ./lib/comments/directives.nu parse-directive; parse-directive "o!echo hi" | to json -r'
  [ "$status" -eq 0 ]
  [ "$(printf '%s\n' "$output" | jq -r '.flags')" = "o" ]
  [ "$(printf '%s\n' "$output" | jq -r '.flag_list | join(",")')" = "o" ]
  [ "$(printf '%s\n' "$output" | jq -r '.script')" = "echo hi" ]
}

@test "parse-directive parses multiple flags" {
  run comments_nu 'use ./lib/comments/directives.nu parse-directive; parse-directive "oi!echo hi" | to json -r'
  [ "$status" -eq 0 ]
  [ "$(printf '%s\n' "$output" | jq -r '.flags')" = "oi" ]
  [ "$(printf '%s\n' "$output" | jq -r '.flag_list | join(",")')" = "o,i" ]
}

@test "parse-directive trims scripts after the bang" {
  run comments_nu 'use ./lib/comments/directives.nu parse-directive; parse-directive "!   echo hi   " | to json -r'
  [ "$status" -eq 0 ]
  [ "$(printf '%s\n' "$output" | jq -r '.script')" = "echo hi" ]
}

@test "parse-directive preserves multiline scripts" {
  run comments_nu $'use ./lib/comments/directives.nu parse-directive; parse-directive "o!\nlet x = 1\n$x" | to json -r'
  [ "$status" -eq 0 ]
  [ "$(printf '%s\n' "$output" | jq -r '.flags')" = "o" ]
  expected=$'let x = 1\n$x'
  [ "$(printf '%s\n' "$output" | jq -r '.script')" = "$expected" ]
}

@test "parse-directive returns null for ordinary text" {
  run comments_nu 'use ./lib/comments/directives.nu parse-directive; parse-directive "ordinary text" | to json -r'
  [ "$status" -eq 0 ]
  [ "$output" = "null" ]
}

@test "parse-directive rejects whitespace before bang as flags" {
  run comments_nu 'use ./lib/comments/directives.nu parse-directive; parse-directive "bad flags!echo hi" | to json -r'
  [ "$status" -eq 0 ]
  [ "$output" = "null" ]
}

@test "parse-directive rejects prose before bang" {
  run comments_nu 'use ./lib/comments/directives.nu parse-directive; parse-directive "TODO! fix this" | to json -r'
  [ "$status" -eq 0 ]
  [ "$output" = "null" ]
}

@test "parse-directive rejects lowercase prose before bang" {
  run comments_nu 'use ./lib/comments/directives.nu parse-directive; parse-directive "todo! fix this" | to json -r'
  [ "$status" -eq 0 ]
  [ "$output" = "null" ]
}

@test "parse-directive recognizes reserved flags before dispatch support" {
  run comments_nu 'use ./lib/comments/directives.nu parse-directive; parse-directive "oi!echo hi" | to json -r'
  [ "$status" -eq 0 ]
  [ "$(printf '%s\n' "$output" | jq -r '.flags')" = "oi" ]
  [ "$(printf '%s\n' "$output" | jq -r '.flag_list | join(",")')" = "o,i" ]
}
