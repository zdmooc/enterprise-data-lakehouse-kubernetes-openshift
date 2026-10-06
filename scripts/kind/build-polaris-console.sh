#!/usr/bin/env bash
source "$(dirname "$0")/common.sh"
guard

POLARIS_TOOLS_SHA=9e6870075dce0cfe4da73f87d61a034545bbea19
IMAGE=apache/polaris-console:kind-9e68700
SRC=.audit/vendor/polaris-tools

if ! docker image inspect "$IMAGE" >/dev/null 2>&1; then
  rm -rf "$SRC"
  mkdir -p "$(dirname "$SRC")"
  git clone --filter=blob:none https://github.com/apache/polaris-tools.git "$SRC"
  git -C "$SRC" checkout --detach "$POLARIS_TOOLS_SHA"
  test "$(git -C "$SRC" rev-parse HEAD)" = "$POLARIS_TOOLS_SHA" || fail "unexpected Polaris Tools source commit"
  docker build -t "$IMAGE" "$SRC/console"
fi

kind load docker-image "$IMAGE" --name "$CLUSTER"

for node in $(lab_nodes); do
  docker exec "$node" crictl images | grep -q 'apache/polaris-console' || fail "Polaris Console image missing on $node"
done

echo "[PASS] Polaris Console image built from official apache/polaris-tools commit $POLARIS_TOOLS_SHA"
