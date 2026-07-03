# Comment extraction helpers shared by comments tasks.

export const SUPPORTED_EXTENSIONS = [md js jsx ts tsx rs go sh py]

export def extension-for-path [target: string] {
  $target | path parse | get extension | str downcase
}

export def is-supported-target [target: string] {
  (extension-for-path $target) in $SUPPORTED_EXTENSIONS
}

export def supported-extension-message [file: string] {
  let extension = (extension-for-path $file)
  let display = if ($extension | is-empty) { "<none>" } else { $".($extension)" }
  $"unsupported file extension: ($display)"
}

export def resolve-target [file: string, base: string] {
  let target = if ($file | str starts-with "/") {
    $file
  } else {
    [$base $file] | path join
  }

  $target | path expand --no-symlink
}

export def extract-comments [target: string] {
  # ast-grep auto-detects the language from the file extension, but tree-sitter
  # grammars do not normalize comment node names. This list scales by known
  # comment-like node kind, not by language. Add kinds here as we encounter
  # grammars whose comments use a different node name.
  let kinds = [comment line_comment block_comment html_block]

  let query_results = (
    $kinds
    | each {|kind|
        let result = (^ast-grep run --kind $kind --json=stream $target | complete)
        if ($result.stdout | str trim | is-empty) {
          []
        } else {
          $result.stdout
          | lines
          | where {|line| ($line | str trim | is-not-empty) }
          | each {|line| $line | from json | insert kind $kind }
        }
      }
  )

  let matches = ($query_results | flatten)
  if (($matches | length) == 0) {
    []
  } else {
    $matches
    | insert __key {|row| $"($row.file):($row.range.byteOffset.start):($row.range.byteOffset.end)" }
    | uniq-by __key
    | sort-by range.byteOffset.start
    | reject __key
  }
}
