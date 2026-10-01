#!/bin/sh
# Run a command in the catmint-linux container, in this repository.
#
#   PLATFORM=linux/amd64 tools/linux/run.sh catmint-gen/build-runtime.sh
#                                      rebuild runtime-linux.bc (x86-64, see below)
#   tools/linux/run.sh ./test.sh
#
# The repository is mounted, so what the command writes lands here. Build
# outputs are kept apart from the host's (a Linux catmint-gen must not
# overwrite the macOS one), in build directories inside the container only.
#
# PLATFORM=linux/amd64 runs it as an x86-64 machine (emulated on Apple
# silicon, so slow). The committed Linux runtime is built that way, because
# x86-64 is where CI checks it:
#
#   PLATFORM=linux/amd64 tools/linux/run.sh catmint-gen/build-runtime.sh
set -e
ROOT=$(cd "$(dirname "$0")/../.." && pwd)
IMAGE=catmint-linux
PLATFORM_ARG=""
if [ -n "$PLATFORM" ]; then
  IMAGE="catmint-linux-$(echo "$PLATFORM" | tr '/' '-')"
  PLATFORM_ARG="--platform $PLATFORM"
fi
# shellcheck disable=SC2086
docker image inspect "$IMAGE" >/dev/null 2>&1 || \
  docker build $PLATFORM_ARG -t "$IMAGE" "$ROOT/tools/linux"
# shellcheck disable=SC2086
exec docker run --rm $PLATFORM_ARG -v "$ROOT:/catmint" -w /catmint "$IMAGE" sh -c "$*"
