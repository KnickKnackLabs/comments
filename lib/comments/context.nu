# Directive context helpers shared by comments tasks.

export def context-location [context: record] {
  let line = ($context.directive.range.start.line + 1)
  $"($context.file):($line)"
}

export def context-field [context: record, field: string] {
  if ($field in ["" "location"]) {
    context-location $context
  } else if $field == "file" {
    $context.file
  } else if $field == "line" {
    $context.directive.range.start.line + 1
  } else if $field == "column" {
    $context.directive.range.start.column + 1
  } else if $field == "directive" {
    $context.directive
  } else if $field == "script" {
    $context.directive.script
  } else {
    error make {msg: $"unknown context field: ($field)"}
  }
}
