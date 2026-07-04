#!/usr/bin/env bats

load test_helper

@test "context-for-directive includes only file and directive" {
  run comments_nu 'use ./lib/comments/dispatch.nu context-for-directive; let directive = {flags: "", flag_list: [], range: {}, text: "", body: "", script: ""}; context-for-directive "/tmp/work/sub/file.md" "a\nb" "/tmp/work" $directive | to json -r'
  [ "$status" -eq 0 ]
  [ "$(printf '%s\n' "$output" | jq -r '.file')" = "/tmp/work/sub/file.md" ]
  [ "$(printf '%s\n' "$output" | jq -r '.directive.script')" = "" ]
  [ "$(printf '%s\n' "$output" | jq -r 'keys | sort | join(",")')" = "directive,file" ]
}
