#!/usr/bin/env bats

load test_helper

@test "duplicate-flags reports repeated flags" {
  run comments_nu 'use ./lib/comments/dispatch.nu duplicate-flags; duplicate-flags {flag_list: [o o i]} | to json -r'
  [ "$status" -eq 0 ]
  [ "$output" = '["o"]' ]
}

@test "duplicate-flags allows unique flags" {
  run comments_nu 'use ./lib/comments/dispatch.nu duplicate-flags; duplicate-flags {flag_list: [o i]} | to json -r'
  [ "$status" -eq 0 ]
  [ "$output" = '[]' ]
}
