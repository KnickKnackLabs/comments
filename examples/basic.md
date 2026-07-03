# Basic comments example

Execute directives and emit the transformed file content to stdout instead of saving changes to this file:

```bash
comments dispatch --stdout examples/basic.md
```

Apply the transformations to the file:

```bash
comments dispatch examples/basic.md
```

## Consume-only directive

The directive below runs and then disappears. Its stdout is ignored because it
uses `!` instead of `o!`.

<!-- !$"this output is intentionally ignored" -->

## Output-replacement directive

The directive below is replaced by its stdout because it uses the `o` flag.

<!-- o!$"hello from comments" -->

## Multiline directive

For multiline scripts, put only `<flags>!` on the first line and start the
script on the next line.

<!--
o!
let rows = [1 2 3]
$rows | length
-->
