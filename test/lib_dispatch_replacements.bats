#!/usr/bin/env bats

load test_helper

@test "apply-replacements-to-content applies byte ranges from bottom to top" {
  run comments_nu 'use ./lib/comments/dispatch.nu apply-replacements-to-content; let replacements = [{start: 0, end: 5, output: "FIRST"}, {start: 13, end: 19, output: "SECOND"}]; apply-replacements-to-content "first middle second" $replacements'
  [ "$status" -eq 0 ]
  [ "$output" = "FIRST middle SECOND" ]
}

@test "apply-replacements-to-content deletes ranges when output is empty" {
  run comments_nu 'use ./lib/comments/dispatch.nu apply-replacements-to-content; let replacements = [{start: 5, end: 11, output: ""}]; apply-replacements-to-content "keep delete keep" $replacements'
  [ "$status" -eq 0 ]
  [ "$output" = "keep  keep" ]
}
