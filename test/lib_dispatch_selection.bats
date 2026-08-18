#!/usr/bin/env bats

load test_helper

@test "parse-dispatch-position converts one-based row and byte column" {
  run comments_nu 'use ./lib/comments/dispatch.nu parse-dispatch-position; parse-dispatch-position "12:34" | to json -r'
  [ "$status" -eq 0 ]
  [ "$output" = '{"line":11,"column":33}' ]
}

@test "parse-dispatch-position rejects zero, missing, and extra coordinates" {
  run comments_nu 'use ./lib/comments/dispatch.nu parse-dispatch-position; ["0:1" "1:0" "1" "1:2:3" "x:y"] | each {|value| parse-dispatch-position $value | default invalid } | to json -r'
  [ "$status" -eq 0 ]
  [ "$output" = '["invalid","invalid","invalid","invalid","invalid"]' ]
}

@test "directives-at-position uses inclusive start and exclusive end" {
  run comments_nu 'use ./lib/comments/dispatch.nu directives-at-position; let directives = [{id: one, range: {start: {line: 2, column: 3}, end: {line: 2, column: 8}}}]; [{line: 2, column: 3} {line: 2, column: 7} {line: 2, column: 8}] | each {|point| directives-at-position $directives $point | get -o id | default [] } | to json -r'
  [ "$status" -eq 0 ]
  [ "$output" = '[["one"],["one"],[]]' ]
}

@test "directives-at-position contains interior rows of multiline directives" {
  run comments_nu 'use ./lib/comments/dispatch.nu directives-at-position; let directives = [{id: multiline, range: {start: {line: 1, column: 4}, end: {line: 3, column: 2}}}]; directives-at-position $directives {line: 2, column: 100} | get id | to json -r'
  [ "$status" -eq 0 ]
  [ "$output" = '["multiline"]' ]
}

@test "directives-at-position exposes ambiguous overlapping ranges" {
  run comments_nu 'use ./lib/comments/dispatch.nu directives-at-position; let directives = [{id: outer, range: {start: {line: 0, column: 0}, end: {line: 2, column: 0}}} {id: inner, range: {start: {line: 1, column: 0}, end: {line: 1, column: 5}}}]; directives-at-position $directives {line: 1, column: 2} | get id | to json -r'
  [ "$status" -eq 0 ]
  [ "$output" = '["outer","inner"]' ]
}
