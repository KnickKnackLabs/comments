# Directive dispatch helpers shared by comments tasks.

export def context-for-directive [target: string, content: string, caller_pwd: string, directive: record] {
  {
    file: $target,
    target_dir: ($target | path dirname),
    caller_pwd: $caller_pwd,
    lines: ($content | lines),
    directive: $directive,
  }
}

export def duplicate-flags [directive: record] {
  $directive.flag_list
  | group-by
  | transpose flag values
  | where {|row| ($row.values | length) > 1 }
  | get flag
}

export def unsupported-flags [directive: record] {
  $directive.flag_list | where {|flag| $flag != "o" }
}

export def directive-writes-output [directive: record] {
  "o" in $directive.flag_list
}

export def run-directive [context: record] {
  let source = "let context = ($env.COMMENTS_CONTEXT_JSON | from json)\n" + $context.directive.script

  with-env {COMMENTS_CONTEXT_JSON: ($context | to json -r)} {
    cd $context.target_dir
    ^nu -c $source | complete
  }
}

export def jsx-expression-comment-wrapper [content: string, directive: record] {
  let extension = ($directive.file | path parse | get extension | str downcase)
  if not ($extension in [jsx tsx]) {
    return null
  }

  if not ($directive.text | str trim | str starts-with "/*") {
    return null
  }

  let start = $directive.range.byteOffset.start
  let end = $directive.range.byteOffset.end
  let before = if $start == 0 {
    ""
  } else {
    $content | str substring 0..<$start
  }
  let after = ($content | str substring $end..)
  let before_trimmed = ($before | str replace -r '\s+$' '')
  let after_trimmed = ($after | str replace -r '^\s+' '')
  let before_len = ($before_trimmed | str length)
  let after_ws_len = (($after | str length) - ($after_trimmed | str length))
  let previous = if $before_len == 0 {
    ""
  } else {
    $before_trimmed | str substring ($before_len - 1)..<$before_len
  }
  let next = if (($after_trimmed | str length) == 0) {
    ""
  } else {
    $after_trimmed | str substring 0..<1
  }

  if not (($previous == "{") or ($next == "}")) {
    return null
  }

  let wrapper_start = if $previous == "{" { $before_len - 1 } else { $start }
  let wrapper_end = if $next == "}" { $end + $after_ws_len + 1 } else { $end }

  {
    standalone: (($previous == "{") and ($next == "}")),
    start: $wrapper_start,
    end: $wrapper_end,
  }
}

export def unsupported-jsx-expression-comment [content: string, directive: record] {
  let wrapper = (jsx-expression-comment-wrapper $content $directive)
  if ($wrapper == null) {
    return null
  }

  if $wrapper.standalone {
    null
  } else {
    "comments dispatch: JSX/TSX directive comments inside expression braces must be the only content in the expression\n"
  }
}

export def replacement-for-directive [content: string, directive: record, output: string] {
  let replacement = {
    start: $directive.range.byteOffset.start,
    end: $directive.range.byteOffset.end,
    output: $output,
  }
  let wrapper = (jsx-expression-comment-wrapper $content $directive)

  if (($wrapper != null) and $wrapper.standalone) {
    $replacement | upsert start $wrapper.start | upsert end $wrapper.end
  } else {
    $replacement
  }
}

export def expand-empty-standalone-replacement [content: string, replacement: record] {
  if ($replacement.output | is-not-empty) {
    return $replacement
  }

  let newline = (char newline)
  let previous_newline = if $replacement.start == 0 {
    -1
  } else {
    $content | str index-of $newline --end --range ..<$replacement.start
  }
  let line_start = $previous_newline + 1

  let content_len = ($content | str length)
  let already_ends_after_newline = if $replacement.end == 0 {
    false
  } else {
    (($content | str substring ($replacement.end - 1)..<$replacement.end) == $newline)
  }
  let next_newline = if $already_ends_after_newline {
    $replacement.end - 1
  } else {
    $content | str index-of $newline --range $replacement.end..
  }
  let line_end = if $next_newline == -1 {
    $content_len
  } else {
    $next_newline + 1
  }

  let before = if $line_start == $replacement.start {
    ""
  } else {
    $content | str substring $line_start..<$replacement.start
  }
  let after_end = if $next_newline == -1 { $line_end } else { $next_newline }
  let after = if $replacement.end >= $after_end {
    ""
  } else {
    $content | str substring $replacement.end..<$after_end
  }

  if (($before | str trim | is-empty) and ($after | str trim | is-empty)) {
    $replacement | upsert start $line_start | upsert end $line_end
  } else {
    $replacement
  }
}

export def apply-replacements-to-content [content: string, replacements: list] {
  mut output = $content
  let normalized_replacements = ($replacements | each {|replacement| expand-empty-standalone-replacement $content $replacement })

  for replacement in ($normalized_replacements | sort-by --reverse start) {
    let before = if $replacement.start == 0 {
      ""
    } else {
      $output | str substring 0..<$replacement.start
    }
    let after = ($output | str substring $replacement.end..)
    $output = $before + $replacement.output + $after
  }

  $output
}

export def apply-replacements [target: string, replacements: list] {
  apply-replacements-to-content (open --raw $target) $replacements | save --force $target
}
