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

@test "rejects descending ranges instead of returning an empty result" {
  run bash runtime/selection-parser.sh '8-3'
  [ "$status" -eq 1 ]
  [[ "$output" == *"invalid_selection_range=8-3"* ]]
}
