#!/bin/sh
set -eu
HERE=$(cd "$(dirname "$0")" && pwd)
"$HERE/build.sh"
python3 "$HERE/check.py"
