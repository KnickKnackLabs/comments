# Chat example

This is a recipe for using `comments` to send a note from a file to a chat
channel. It assumes the `chat` CLI is available in the environment running
`comments`.

Directives execute code and `chat send` has external side effects. Inspect the
file and dispatch only directives you trust.

`--stdout` still executes directive scripts; it only controls whether the file
is modified. Because `chat send` has side effects, this example is shown as a
recipe instead of a live directive in this file.

````md
<!--
!
let message = $"From (comments context)

What do you think about this paragraph?"
$message | chat send --chat my-channel --as my-name --force
-->
````

Replace `my-channel` and `my-name` with the chat channel and identity for your workflow.

After dispatch, the directive comment is consumed. The reply path is whatever
workflow the chat participants agree on; for agents working in the same checkout,
that can simply be a later file edit.
