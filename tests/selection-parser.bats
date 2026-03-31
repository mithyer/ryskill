#!/usr/bin/env bats

@test "parses compact digits" {
  run bash runtime/selection-parser.sh 135
  [ "$status" -eq 0 ]
  [ "$output" = "1 3 5" ]
}

@test "parses ranges and commas in display order" {
  run bash runtime/selection-parser.sh '3,1-2,2'
  [ "$status" -eq 0 ]
  [ "$output" = "1 2 3" ]
}
