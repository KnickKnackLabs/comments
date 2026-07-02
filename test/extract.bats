#!/usr/bin/env bats

load test_helper

@test "extract returns JavaScript line comments" {
  cat > "$BATS_TEST_TMPDIR/sample.js" <<'EOF'
// !chat hello
console.log('x')
EOF

  COMMENTS_CALLER_PWD="$BATS_TEST_TMPDIR" run comments extract sample.js
  [ "$status" -eq 0 ]
  [ "$(printf '%s\n' "$output" | jq -r '.kind')" = "comment" ]
  [[ "$(printf '%s\n' "$output" | jq -r '.text')" == "// !chat hello" ]]
}

@test "extract returns JavaScript block comments" {
  cat > "$BATS_TEST_TMPDIR/sample.js" <<'EOF'
/*
!chat hello
*/
console.log('x')
EOF

  COMMENTS_CALLER_PWD="$BATS_TEST_TMPDIR" run comments extract sample.js
  [ "$status" -eq 0 ]
  [ "$(printf '%s\n' "$output" | jq -r '.kind')" = "comment" ]
  printf '%s\n' "$output" | jq -e '.text | contains("!chat hello")' >/dev/null
}

@test "extract returns JSX comments" {
  cat > "$BATS_TEST_TMPDIR/sample.jsx" <<'EOF'
// !echo "from jsx"
export const value = 1
EOF

  COMMENTS_CALLER_PWD="$BATS_TEST_TMPDIR" run comments extract sample.jsx
  [ "$status" -eq 0 ]
  [ "$(printf '%s\n' "$output" | jq -r '.kind')" = "comment" ]
  [ "$(printf '%s\n' "$output" | jq -r '.text')" = "// !echo \"from jsx\"" ]
}

@test "extract returns TypeScript comments" {
  cat > "$BATS_TEST_TMPDIR/sample.ts" <<'EOF'
// !echo "from ts"
const value: number = 1
EOF

  COMMENTS_CALLER_PWD="$BATS_TEST_TMPDIR" run comments extract sample.ts
  [ "$status" -eq 0 ]
  [ "$(printf '%s\n' "$output" | jq -r '.kind')" = "comment" ]
  [ "$(printf '%s\n' "$output" | jq -r '.text')" = "// !echo \"from ts\"" ]
}

@test "extract returns TSX comments" {
  cat > "$BATS_TEST_TMPDIR/sample.tsx" <<'EOF'
// !echo "from tsx"
export const value = <div />
EOF

  COMMENTS_CALLER_PWD="$BATS_TEST_TMPDIR" run comments extract sample.tsx
  [ "$status" -eq 0 ]
  [ "$(printf '%s\n' "$output" | jq -r '.kind')" = "comment" ]
  [ "$(printf '%s\n' "$output" | jq -r '.text')" = "// !echo \"from tsx\"" ]
}

@test "extract returns Rust line comments" {
  cat > "$BATS_TEST_TMPDIR/sample.rs" <<'EOF'
fn main() {
  // !chat hello
}
EOF

  COMMENTS_CALLER_PWD="$BATS_TEST_TMPDIR" run comments extract sample.rs
  [ "$status" -eq 0 ]
  [ "$(printf '%s\n' "$output" | jq -r '.kind')" = "line_comment" ]
  [[ "$(printf '%s\n' "$output" | jq -r '.text')" == "// !chat hello" ]]
}

@test "extract returns Go comments" {
  cat > "$BATS_TEST_TMPDIR/sample.go" <<'EOF'
package main
// !echo "from go"
func main() {}
EOF

  COMMENTS_CALLER_PWD="$BATS_TEST_TMPDIR" run comments extract sample.go
  [ "$status" -eq 0 ]
  [ "$(printf '%s\n' "$output" | jq -r '.kind')" = "comment" ]
  [ "$(printf '%s\n' "$output" | jq -r '.text')" = "// !echo \"from go\"" ]
}

@test "extract returns shell comments" {
  cat > "$BATS_TEST_TMPDIR/sample.sh" <<'EOF'
# !echo "from shell"
echo hi
EOF

  COMMENTS_CALLER_PWD="$BATS_TEST_TMPDIR" run comments extract sample.sh
  [ "$status" -eq 0 ]
  [ "$(printf '%s\n' "$output" | jq -r '.kind')" = "comment" ]
  [ "$(printf '%s\n' "$output" | jq -r '.text')" = "# !echo \"from shell\"" ]
}

@test "extract returns Python comments" {
  cat > "$BATS_TEST_TMPDIR/sample.py" <<'EOF'
# !echo "from python"
print("hi")
EOF

  COMMENTS_CALLER_PWD="$BATS_TEST_TMPDIR" run comments extract sample.py
  [ "$status" -eq 0 ]
  [ "$(printf '%s\n' "$output" | jq -r '.kind')" = "comment" ]
  [ "$(printf '%s\n' "$output" | jq -r '.text')" = "# !echo \"from python\"" ]
}

@test "extract returns multiline Markdown HTML comments" {
  cat > "$BATS_TEST_TMPDIR/sample.md" <<'EOF'
# Title

<!--
!chat send "hello"
  multiline body
-->
EOF

  COMMENTS_CALLER_PWD="$BATS_TEST_TMPDIR" run comments extract sample.md
  [ "$status" -eq 0 ]
  [ "$(printf '%s\n' "$output" | jq -r '.kind')" = "html_block" ]
  printf '%s\n' "$output" | jq -e '.text | contains("multiline body")' >/dev/null
  [ "$(printf '%s\n' "$output" | jq -r '.range.start.line')" = "2" ]
}

@test "extract returns comments sorted by byte offset" {
  cat > "$BATS_TEST_TMPDIR/sample.js" <<'EOF'
// first
console.log('x')
// second
EOF

  COMMENTS_CALLER_PWD="$BATS_TEST_TMPDIR" run comments extract sample.js
  [ "$status" -eq 0 ]
  [ "$(printf '%s\n' "$output" | jq -s 'length')" = "2" ]
  [ "$(printf '%s\n' "$output" | jq -sr '.[0].text')" = "// first" ]
  [ "$(printf '%s\n' "$output" | jq -sr '.[1].text')" = "// second" ]
}

@test "extract accepts absolute paths" {
  cat > "$BATS_TEST_TMPDIR/sample.rs" <<'EOF'
// absolute
fn main() {}
EOF

  run comments extract "$BATS_TEST_TMPDIR/sample.rs"
  [ "$status" -eq 0 ]
  [ "$(printf '%s\n' "$output" | jq -r '.text')" = "// absolute" ]
}

@test "extract exits zero with no output when a supported file has no comments" {
  cat > "$BATS_TEST_TMPDIR/sample.js" <<'EOF'
console.log('x')
EOF

  COMMENTS_CALLER_PWD="$BATS_TEST_TMPDIR" run comments extract sample.js
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "extract exits nonzero for unsupported file extensions" {
  cat > "$BATS_TEST_TMPDIR/sample.txt" <<'EOF'
# !text
EOF

  COMMENTS_CALLER_PWD="$BATS_TEST_TMPDIR" run comments extract sample.txt
  [ "$status" -ne 0 ]
  [[ "$output" == *"unsupported file extension: .txt"* ]]
}

@test "extract exits nonzero for missing files" {
  COMMENTS_CALLER_PWD="$BATS_TEST_TMPDIR" run comments extract missing.md
  [ "$status" -ne 0 ]
  [[ "$output" == *"file not found"* ]]
}
