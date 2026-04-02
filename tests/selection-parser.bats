#!/usr/bin/env bats

@test "treats compact multi-digit selection as a single candidate index" {
  run bash runtime/selection-parser.sh 12
  [ "$status" -eq 0 ]
  [ "$output" = "12" ]
}

@test "still supports space-separated digits" {
  run bash runtime/selection-parser.sh '1 3 5'
  [ "$status" -eq 0 ]
  [ "$output" = "1 3 5" ]
}

@test "still supports ranges commas and mixed separators" {
  run bash runtime/selection-parser.sh '1-3,5'
  [ "$status" -eq 0 ]
  [ "$output" = "1 2 3 5" ]
}

@test "accepts 0 for over flow" {
  run bash runtime/selection-parser.sh '0'
  [ "$status" -eq 0 ]
  [ "$output" = "0" ]
}

