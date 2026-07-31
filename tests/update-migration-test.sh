#!/usr/bin/env bash

set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT/system_files/usr/lib/armada/update-lib"

assert_registry() {
    local expected="$1" ref="$2" actual
    actual="$(armada_registry_from_ref "$ref")"
    if [[ "$actual" != "$expected" ]]; then
        printf 'registry parse failed: expected %q, got %q for %q\n' \
            "$expected" "$actual" "$ref" >&2
        exit 1
    fi
}

assert_registry "$ARMADA_LEGACY_REGISTRY" \
    "ostree-image-signed:docker://${ARMADA_LEGACY_REGISTRY}:stable"
assert_registry "$ARMADA_CANONICAL_REGISTRY" \
    "ostree-image-signed:docker://${ARMADA_CANONICAL_REGISTRY}@sha256:deadbeef"
assert_registry "$ARMADA_CANONICAL_REGISTRY" \
    "docker://${ARMADA_CANONICAL_REGISTRY}:testing"
assert_registry "" \
    "ostree-image-signed:docker://example.invalid/${ARMADA_LEGACY_REGISTRY}:stable"

python3 - "$ROOT" <<'PY'
import json
from pathlib import Path
import sys
import tomllib

root = Path(sys.argv[1])
canonical = "ghcr.io/armada-os/armada"
legacy = "ghcr.io/virtudude/armada"
mirror_path = (
    root / "system_files/etc/containers/registries.conf.d/50-armada-migration.conf"
)

policy = json.loads(
    (root / "system_files/etc/containers/policy.json").read_text()
)
docker = policy["transports"]["docker"]
assert docker[legacy][0]["signedIdentity"] == {
    "type": "exactRepository",
    "dockerRepository": canonical,
}
assert docker[canonical][0]["signedIdentity"] == {"type": "matchRepository"}

assert mirror_path.is_file()
assert not (
    root
    / "system_files/usr/share/containers/registries.conf.d/50-armada-migration.conf"
).exists()
mirror = tomllib.loads(mirror_path.read_text())
registry = mirror["registry"][0]
assert registry["prefix"] == legacy
assert registry["location"] == legacy
assert registry["mirror"] == [{"location": canonical}]

sigstore = (
    root / "system_files/etc/containers/registries.d/ghcr-armada.yaml"
).read_text()
for repository in (legacy, canonical):
    assert f"  {repository}:\n    use-sigstore-attachments: true" in sigstore
PY

printf 'update repository migration test passed\n'
