#!/usr/bin/env bash
source "$(dirname "$0")/common.sh"
guard

POLARIS_TOOLS_SHA=9e6870075dce0cfe4da73f87d61a034545bbea19
IMAGE=apache/polaris-console:kind-9e68700
SRC=.audit/vendor/polaris-tools

if ! docker image inspect "$IMAGE" >/dev/null 2>&1; then
  rm -rf "$SRC"
  mkdir -p "$(dirname "$SRC")"

  # Windows/Git Bash: checkout only console/. The full apache/polaris-tools
  # repository contains deeply nested Maven test paths that can exceed the
  # Win32 path-length limit even though they are irrelevant to this image.
  git clone --filter=blob:none --no-checkout https://github.com/apache/polaris-tools.git "$SRC"
  git -C "$SRC" sparse-checkout init --cone
  git -C "$SRC" sparse-checkout set console
  git -C "$SRC" checkout --detach "$POLARIS_TOOLS_SHA"

  test "$(git -C "$SRC" rev-parse HEAD)" = "$POLARIS_TOOLS_SHA" || fail "unexpected Polaris Tools source commit"
  test -f "$SRC/console/docker/Dockerfile" || fail "Polaris Console Dockerfile missing after sparse checkout"

  docker build -t "$IMAGE" -f "$SRC/console/docker/Dockerfile" "$SRC/console"
fi

kind load docker-image "$IMAGE" --name "$CLUSTER"

for node in $(lab_nodes); do
  docker exec "$node" crictl images | grep -q 'apache/polaris-console' || fail "Polaris Console image missing on $node"
done

echo "[PASS] Polaris Console image built from official apache/polaris-tools commit $POLARIS_TOOLS_SHA"
