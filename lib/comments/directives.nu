# Directive parsing helpers shared by comments tasks.

export def normalize-comment [text: string] {
  let trimmed = ($text | str trim)

  if (($trimmed | str starts-with "<!--") and ($trimmed | str ends-with "-->")) {
    $trimmed
    | str replace -r '^\s*<!--' ''
    | str replace -r '-->\s*$' ''
    | str trim
  } else if (($trimmed | str starts-with "/*") and ($trimmed | str ends-with "*/")) {
    $trimmed
    | str replace -r '^\s*/\*' ''
    | str replace -r '\*/\s*$' ''
    | str trim
  } else if ($trimmed | str starts-with "//") {
    $trimmed
    | str replace -r '^\s*//\s?' ''
    | str trim
  } else if ($trimmed | str starts-with "#") {
    $trimmed
    | str replace -r '^\s*#\s?' ''
    | str trim
  } else {
    $trimmed
  }
}

export def parse-directive [body: string] {
  let parsed = ($body | parse --regex '^(?<flags>[oi]*)!(?<script>[\s\S]*)$')
  if (($parsed | length) == 0) {
    null
  } else {
    let first = ($parsed | first)
    let flags = $first.flags
    {
      flags: $flags,
      flag_list: ($flags | split chars),
      script: ($first.script | str trim)
    }
  }
}

export def directive-from-comment [comment: record] {
  let body = (normalize-comment $comment.text)
  let directive = (parse-directive $body)

  if $directive == null {
    null
  } else {
    {
      file: $comment.file,
      kind: $comment.kind,
      range: $comment.range,
      text: $comment.text,
      body: $body,
      flags: $directive.flags,
      flag_list: $directive.flag_list,
      script: $directive.script,
    }
  }
}
