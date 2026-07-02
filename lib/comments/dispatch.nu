# Directive dispatch helpers shared by comments tasks.

export def context-for-directive [target: string, directive: record] {
  {
    file: $target,
    lines: (open --raw $target | lines),
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

export def apply-replacements-to-content [content: string, replacements: list] {
  mut output = $content

  for replacement in ($replacements | sort-by --reverse start) {
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
