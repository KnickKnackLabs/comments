# Project-local comment task example

`comments` stays generic: it finds directives, exposes context, runs scripts,
and edits files. A project can add a tiny local helper for its own review or
chat workflow.

This example shows how to support the short directive form:

```md
<!-- ! "This section is unclear." | mise comment -->
```

The trick is a mise namespace default task: `.mise/tasks/comment/_default`.
`mise run` is optional, so `mise comment` works.

## Project setup

Declare the tools the directive and helper need:

```toml
# mise.toml
[tools]
"shiv:comments" = "0.2"
"shiv:chat" = "0.1"

[settings]
quiet = true
task_output = "interleave"
```

## Default task

Keep the default task tiny and delegate to a concrete helper. This lets users
write `mise comment` in directives while the implementation can live at a more
specific task such as `comment:chat`.

```bash
#!/usr/bin/env bash
# .mise/tasks/comment/_default
#MISE description="Send a directive message to the project comment channel"
#USAGE arg "[message]" default="" help="Message to send; reads stdin when omitted"
set -euo pipefail

if [ -n "${usage_message:-}" ]; then
  exec mise run -q comment:chat "$usage_message"
else
  exec mise run -q comment:chat
fi
```

## Chat helper

This helper reads a message from its argument or stdin, asks `comments context`
where the directive lives, then sends a formatted note to chat.

```bash
#!/usr/bin/env bash
# .mise/tasks/comment/chat
#MISE description="Send a directive message to chat with comments context"
#USAGE arg "[message]" default="" help="Message to send; reads stdin when omitted"
set -euo pipefail

message="${usage_message:-}"
if [ -z "$message" ]; then
  message="$(cat)"
fi

if [ -z "${message//[[:space:]]/}" ]; then
  echo "comment:chat: message is required on stdin or as an argument" >&2
  exit 1
fi

context_json="$(comments context --json)"
location="$(
  printf '%s' "$context_json" \
    | jq -r '.file as $file | (.directive.range.start.line + 1) as $line | "\($file):\($line)"'
)"

channel="${COMMENT_CHAT_CHANNEL:-default}"
sender="${COMMENT_CHAT_AS:-${CHAT_IDENTITY:-$(whoami)}}"

{
  printf 'From %s\n\n' "$location"
  printf '%s\n' "$message"
} | chat send --chat "$channel" --as "$sender" --force -
```

## Use from a directive

```md
<!-- ! "Can you look at this paragraph?" | mise comment -->
```

When dispatch runs, the directive is consumed and the chat message includes the
source file and line.

For Zed, run `comments` through the project mise environment so helper tools
come from `mise.toml`:

```json
[
  {
    "label": "comments: dispatch current file",
    "command": "mise exec -- comments dispatch \"$ZED_FILE\"",
    "save": "current",
    "hide": "on_success"
  }
]
```
