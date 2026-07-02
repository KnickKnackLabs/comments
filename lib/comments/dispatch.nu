# Directive dispatch helpers shared by comments tasks.

export def context-for-directive [target: string, directive: record] {
  {
    file: $target,
    lines: (open --raw $target | lines),
    directive: $directive,
  }
}

export def unsupported-flags [directive: record] {
  $directive.flag_list
}

export def run-directive [context: record] {
  let source = "let context = ($env.COMMENTS_CONTEXT_JSON | from json)\n" + $context.directive.script

  with-env {COMMENTS_CONTEXT_JSON: ($context | to json -r)} {
    ^nu -c $source | complete
  }
}
