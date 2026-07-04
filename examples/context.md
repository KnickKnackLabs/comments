# Context example

This example shows directives using `comments context` from inside their own
scripts. That is the bridge pattern for tools that want file-local context
without coupling `comments` to a specific consumer.

Preview the transformations without editing this file:

```bash
comments dispatch --stdout examples/context.md
```

Apply the transformations to this file:

```bash
comments dispatch examples/context.md
```

## Smallest useful context

The default `comments context` output is a compact `file:line` string.

<!-- o! comments context -->

## Curated structured context

The directive below asks for JSON context, parses it into Nu data, then formats
the output as Markdown. The script is intentionally rendered as a code block
instead of a table cell, because multi-line strings make Markdown tables hard to
read.

<!--
o!
let ctx = (comments context --json | from json)
[
  $"file: `($ctx.file)`"
  $"line: `($ctx.directive.range.start.line + 1)`"
  ""
  "script:"
  "````nu"
  $ctx.directive.script
  "````"
  ""
] | str join "\n"
-->

## Public context dump

This is noisier, but it is the best "what is available?" demo. It includes
the file path and public directive record.

<!-- o! comments context --json | from json | to md --pretty -->
