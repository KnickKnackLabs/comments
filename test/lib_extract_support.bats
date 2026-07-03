#!/usr/bin/env bats

load test_helper

@test "is-supported-target accepts the initial supported extension set" {
  run comments_nu 'use ./lib/comments/extract.nu is-supported-target; [file.md file.js file.jsx file.ts file.tsx file.rs file.go file.sh file.py] | each {|file| is-supported-target $file } | to json -r'
  [ "$status" -eq 0 ]
  [ "$output" = "[true,true,true,true,true,true,true,true,true]" ]
}

@test "is-supported-target rejects unsupported extensions" {
  run comments_nu 'use ./lib/comments/extract.nu is-supported-target; [file.txt file.nu Makefile] | each {|file| is-supported-target $file } | to json -r'
  [ "$status" -eq 0 ]
  [ "$output" = "[false,false,false]" ]
}

@test "supported-extension-message formats missing and present extensions" {
  run comments_nu 'use ./lib/comments/extract.nu supported-extension-message; [README, file.txt] | each {|file| supported-extension-message $file } | to json -r'
  [ "$status" -eq 0 ]
  [ "$output" = '["unsupported file extension: <none>","unsupported file extension: .txt"]' ]
}
