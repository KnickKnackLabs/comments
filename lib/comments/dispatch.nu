# Directive dispatch helpers shared by comments tasks.

export def context-for-directive [target: string, content: string, directive: record] {
  {
    file: $target,
    lines: ($content | lines),
    directive: $directive,
  }
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
    ^nu -c $source | complete
  }
}

export def replacement-for-directive [directive: record, output: string] {
  {
    start: $directive.range.byteOffset.start,
    end: $directive.range.byteOffset.end,
    output: $output,
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
