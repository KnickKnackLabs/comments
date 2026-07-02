# Chat example

This is a recipe for using `comments` to send a note from a file to a chat
channel. It assumes the `chat` CLI is available in the environment running
`comments`.

`--stdout` still executes directive scripts; it only controls whether the file
is modified. Because `chat send` has side effects, this example is shown as a
recipe instead of a live directive in this file.

````md
<!--
!
let message = $"From ($context.file):($context.directive.range.start.line + 1)

What do you think about this paragraph?"
$message | chat send --chat fold --as ikma --force -
-->
````

After dispatch, the directive comment is consumed. The reply path is whatever
workflow the chat participants agree on; for agents working in the same checkout,
that can simply be a later file edit.
