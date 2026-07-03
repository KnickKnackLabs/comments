#!/usr/bin/env bats

load test_helper

@test "normalize-comment strips JavaScript line comment markers" {
  run comments_nu 'use ./lib/comments/directives.nu normalize-comment; normalize-comment "// !chat send hi"'
  [ "$status" -eq 0 ]
  [ "$output" = "!chat send hi" ]
}

@test "normalize-comment strips shell line comment markers" {
  run comments_nu 'use ./lib/comments/directives.nu normalize-comment; normalize-comment "# !chat send hi"'
  [ "$status" -eq 0 ]
  [ "$output" = "!chat send hi" ]
}

@test "normalize-comment strips block comment markers and preserves multiline body" {
  run comments_nu $'use ./lib/comments/directives.nu normalize-comment; normalize-comment "/*\n!\nlet x = 1\n*/"'
  [ "$status" -eq 0 ]
  expected=$'!\nlet x = 1'
  [ "$output" = "$expected" ]
}

@test "normalize-comment strips single-line Markdown HTML comment markers" {
  run comments_nu 'use ./lib/comments/directives.nu normalize-comment; normalize-comment "<!-- o!echo hi -->"'
  [ "$status" -eq 0 ]
  [ "$output" = "o!echo hi" ]
}

@test "normalize-comment strips multiline Markdown HTML comment markers" {
  run comments_nu $'use ./lib/comments/directives.nu normalize-comment; normalize-comment "<!--\no!\nlet x = 1\n-->"'
  [ "$status" -eq 0 ]
  expected=$'o!\nlet x = 1'
  [ "$output" = "$expected" ]
}

@test "normalize-comment leaves unknown comment text trimmed" {
  run comments_nu 'use ./lib/comments/directives.nu normalize-comment; normalize-comment "  ordinary text  "'
  [ "$status" -eq 0 ]
  [ "$output" = "ordinary text" ]
}
