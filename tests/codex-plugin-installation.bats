#!/usr/bin/env bats

@test "codex marketplace lists ryskill as a local installable plugin" {
  run python3 - <<'PY'
import json
from pathlib import Path

marketplace_path = Path("/Users/ray/Documents/projects/ryskill/.agents/plugins/marketplace.json")
marketplace = json.loads(marketplace_path.read_text(encoding="utf-8"))

entry = next(item for item in marketplace["plugins"] if item["name"] == "ryskill")
assert entry["source"]["source"] == "local"
assert entry["source"]["path"] == "./plugins/ryskill"
assert entry["policy"]["installation"] == "AVAILABLE"
assert entry["policy"]["authentication"] == "ON_INSTALL"
assert entry["category"] == "Productivity"
PY
  [ "$status" -eq 0 ]
}

@test "codex plugin manifest exposes ryskill metadata and skills path" {
  run python3 - <<'PY'
import json
from pathlib import Path

manifest_path = Path("/Users/ray/Documents/projects/ryskill/plugins/ryskill/.codex-plugin/plugin.json")
manifest = json.loads(manifest_path.read_text(encoding="utf-8"))

assert manifest["name"] == "ryskill"
assert manifest["version"] == "0.2.5"
assert manifest["skills"] == "./skills/"
assert manifest["interface"]["displayName"] == "RY Skill"
PY
  [ "$status" -eq 0 ]
}

@test "codex skill entry for ry-git-commit exists" {
  run test -f "$BATS_TEST_DIRNAME/../plugins/ryskill/skills/ry-git-commit/SKILL.md"
  [ "$status" -eq 0 ]
}
