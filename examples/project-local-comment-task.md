# Project-local comment task example

`comments` stays generic: it finds directives, exposes context, runs scripts,
and edits files. A project can add a small local helper for its own review or
chat workflow.

This example supports the short directive form:

```md
<!-- ! "This section is unclear." | mise comment -->
```

Directives execute code. Inspect the file and dispatch only directives you
trust. Do not run whole-file dispatch against an untrusted checkout merely
because the comments look like prose.

## Project setup

Declare every tool used by the directive and helper:

```toml
# mise.toml
[tools]
"shiv:comments" = "0.2"
"shiv:chat" = "0.2"
jq = "1"

[settings]
quiet = true
task_output = "interleave"
```

## Default task

Use a mise namespace default task so `mise comment` works. Execute the concrete
helper directly instead of starting a second mise process. The parent task has
already parsed and exported `usage_message`.

```bash
#!/usr/bin/env bash
# .mise/tasks/comment/_default
#MISE description="Send a directive message to the project comment channel"
#USAGE arg "[message]" default="" help="Message to send; reads stdin when omitted"
set -euo pipefail

exec "$MISE_CONFIG_ROOT/.mise/tasks/comment/chat"
```

## Chat helper

During dispatch, `COMMENTS_CONTEXT_JSON` contains the same public JSON record
returned by `comments context --json`. Reading it directly avoids launching a
second `comments` process on latency-sensitive editor paths.

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

context_json="${COMMENTS_CONTEXT_JSON:-}"
if [ -z "${context_json//[[:space:]]/}" ]; then
  echo "comment:chat: COMMENTS_CONTEXT_JSON is required; run through comments dispatch" >&2
  exit 1
fi

if ! location="$(
  printf '%s' "$context_json" \
    | jq -er '
        select((.file | type) == "string")
        | select((.directive.range.start.line | type) == "number")
        | "\(.file):\(.directive.range.start.line + 1)"
      ' 2>/dev/null
)"; then
  echo "comment:chat: COMMENTS_CONTEXT_JSON is invalid or missing file/line context" >&2
  exit 1
fi

channel="${COMMENT_CHAT_CHANNEL:-default}"
sender="${COMMENT_CHAT_AS:-${CHAT_IDENTITY:-$(whoami)}}"
chat_bin="${CHAT:-chat}"

{
  printf 'From %s\n\n' "$location"
  printf '%s\n' "$message"
} | "$chat_bin" send --chat "$channel" --as "$sender" --force
```

A human-authored editor comment can inherit an unrelated ambient
`CHAT_IDENTITY`. Set `COMMENT_CHAT_AS` explicitly in the project task when
attribution matters.

## Use from a directive

```md
<!-- ! "Can you look at this paragraph?" | mise comment -->
```

A successful consume-only directive is removed after its chat message sends.
The message includes the source file and line.

## Zed task ergonomics

The minimal integration remains portable:

```bash
comments integrations zed --keymap
```

A project can opt into proven local ergonomics without making them generic
defaults:

```bash
comments integrations zed \
  --keymap \
  --reveal never \
  --shell-program /bin/zsh \
  --shell-arg=-f \
  --env COMMENT_CHAT_AS=or
```

`--reveal never` hides the task terminal, `/bin/zsh -f` is a local macOS shell
choice, and the environment entry makes the human sender explicit. Choose
values appropriate to the project and machine.

Snippet text and recipients remain project policy. Install an inline Markdown
snippet through `ctl` when useful:

```bash
ctl zed keymap check-snippet \
  --context 'Editor && extension == md' \
  --keystroke 'cmd-k i' \
  --snippet '<!-- ! "@ikma ${1:feedback}" | mise comment -->$0'

ctl zed keymap bind-snippet \
  --context 'Editor && extension == md' \
  --keystroke 'cmd-k i' \
  --snippet '<!-- ! "@ikma ${1:feedback}" | mise comment -->$0'
```

This keeps `@ikma`, `mise comment`, chat identity, and shortcut choice outside
`comments` core.
