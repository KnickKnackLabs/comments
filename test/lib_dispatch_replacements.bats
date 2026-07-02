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

@test "apply-replacements-to-content removes a standalone empty-output line" {
  run comments_nu 'use ./lib/comments/dispatch.nu apply-replacements-to-content; let replacements = [{start: 2, end: 7, output: ""}]; apply-replacements-to-content "1\nABCDE\n3\n" $replacements'
  [ "$status" -eq 0 ]
  [ "$output" = $'1\n3' ]
}

@test "apply-replacements-to-content removes an indented standalone empty-output line" {
  run comments_nu 'use ./lib/comments/dispatch.nu apply-replacements-to-content; let replacements = [{start: 4, end: 9, output: ""}]; apply-replacements-to-content "1\n  ABCDE\n3\n" $replacements'
  [ "$status" -eq 0 ]
  [ "$output" = $'1\n3' ]
}

@test "apply-replacements-to-content preserves inline empty-output replacement behavior" {
  run comments_nu 'use ./lib/comments/dispatch.nu apply-replacements-to-content; let replacements = [{start: 2, end: 7, output: ""}]; apply-replacements-to-content "1 ABCDE 3\n" $replacements'
  [ "$status" -eq 0 ]
  [ "$output" = "1  3" ]
}
