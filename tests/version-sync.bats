#!/usr/bin/env bats

@test "source and marketplace plugin versions stay aligned at 0.2.2" {
  source_version="$(python3 -c 'import json; print(json.load(open("/Users/ray/Documents/projects/ryskill/plugin.json"))["version"])')"
  marketplace_version="$(python3 -c 'import json; print(json.load(open("/Users/ray/.claude/plugins/cache/ryskill-marketplace/ryskill/0.2.1/.claude-plugin/plugin.json"))["version"])')"

  [ "$source_version" = "0.2.2" ]
  [ "$marketplace_version" = "0.2.2" ]
}
