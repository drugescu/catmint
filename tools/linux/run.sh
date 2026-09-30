#!/bin/sh
# Run a command in the catmint-linux container, in this repository.
#
#   tools/linux/run.sh catmint-gen/build-runtime.sh     rebuild runtime-linux.bc
#   tools/linux/run.sh ./test.sh
#
# The repository is mounted, so what the command writes lands here. Build
# outputs are kept apart from the host's (a Linux catmint-gen must not
# overwrite the macOS one), in build directories inside the container only.
set -e
ROOT=$(cd "$(dirname "$0")/../.." && pwd)
docker image inspect catmint-linux >/dev/null 2>&1 || \
  docker build -t catmint-linux "$ROOT/tools/linux"
exec docker run --rm -v "$ROOT:/catmint" -w /catmint catmint-linux sh -c "$*"
