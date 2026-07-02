#!/usr/bin/env bats

load test_helper

@test "directive-from-comment builds directive records" {
  run comments_nu 'use ./lib/comments/directives.nu directive-from-comment; let comment = {file: sample.md, kind: html_block, range: {start: {line: 0, column: 0}, end: {line: 0, column: 20}, byteOffset: {start: 0, end: 20}}, text: "<!-- o!echo hi -->"}; directive-from-comment $comment | to json -r'
  [ "$status" -eq 0 ]
  [ "$(printf '%s\n' "$output" | jq -r '.file')" = "sample.md" ]
  [ "$(printf '%s\n' "$output" | jq -r '.kind')" = "html_block" ]
  [ "$(printf '%s\n' "$output" | jq -r '.flags')" = "o" ]
  [ "$(printf '%s\n' "$output" | jq -r '.script')" = "echo hi" ]
  [ "$(printf '%s\n' "$output" | jq -r '.range.start.line')" = "0" ]
}

@test "directive-from-comment preserves original text and normalized body" {
  run comments_nu 'use ./lib/comments/directives.nu directive-from-comment; let comment = {file: sample.js, kind: comment, range: {}, text: "// !chat hi"}; directive-from-comment $comment | to json -r'
  [ "$status" -eq 0 ]
  [ "$(printf '%s\n' "$output" | jq -r '.text')" = "// !chat hi" ]
  [ "$(printf '%s\n' "$output" | jq -r '.body')" = "!chat hi" ]
}

@test "directive-from-comment returns null for non-directive comments" {
  run comments_nu 'use ./lib/comments/directives.nu directive-from-comment; let comment = {file: sample.js, kind: comment, range: {}, text: "// ordinary"}; directive-from-comment $comment | to json -r'
  [ "$status" -eq 0 ]
  [ "$output" = "null" ]
}
