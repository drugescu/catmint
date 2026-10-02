#!/bin/sh
# play.sh - run every tests/*.play against pad and check what each says should
# happen.
#
#   ./build.sh && ./play.sh
#   SHOTS=/some/dir ./play.sh      also keep each test's final frame as a BMP
#
# A play file drives pad with real SDL input events and, for typed text, the
# program's own text handler (see Pad.send in pad.cm). Its header says how many
# frames to run, what to start with, and what must, or must not, appear in the
# state pad prints afterwards:
#
#   # frames 10
#   # files notes.txt=hello   (files made in the working directory first)
#   # exec catmintc=#!/bin/sh\necho hi   (a file made executable)
#   # open notes.txt          (start with this file)
#   # args --catmintc @ROOT@/catmintc   (more arguments; @ROOT@ is the repository)
#   # expect cursor 1 6
#   # absent quit 1
#   # pixels 0 0 960 640 30 34 41 N
#   # file notes.txt=hello    (what a file holds, afterwards)
#
# "# pixels x0 y0 x1 y1 r g b n" counts pixels of one exact colour in the
# half-open rectangle of the frame the run saved: what pad drew, not what it
# says it drew. A line "# pixels ... n" with n written as "none" means there
# must be no such pixel, and "some" means at least one.
#
# The expectations are written by hand from the design, not recorded from a
# run, so a test can disagree with pad.
HERE=$(cd "$(dirname "$0")" && pwd)
ROOT=$(cd "$HERE/../.." && pwd)
PAD="${PAD:-$HERE/pad}"
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
export SDL_VIDEODRIVER=dummy SDL_RENDER_DRIVER=software SDL_AUDIODRIVER=dummy
failed=0
total=0
for play in "$HERE"/tests/*.play; do
  name=$(basename "$play" .play)
  total=$((total + 1))
  frames=$(sed -n 's/^# frames \([0-9]*\)$/\1/p' "$play")
  shot="$TMP/$name.bmp"
  [ -n "$SHOTS" ] && shot="$SHOTS/$name.bmp"
  # Each test works in a directory of its own.
  dir="$TMP/work-$name"
  mkdir -p "$dir"
  # "# files a.txt=text": make files first. \n in the text is a newline.
  while IFS= read -r spec; do
    [ -z "$spec" ] && continue
    fname=${spec%%=*}
    mkdir -p "$dir/$(dirname "$fname")"
    printf '%b' "${spec#*=}" > "$dir/$fname"
  done <<FILES
$(sed -n 's/^# files //p' "$play")
FILES
  # "# exec name=text": the same, made executable (a stand-in for a program).
  while IFS= read -r spec; do
    [ -z "$spec" ] && continue
    fname=${spec%%=*}
    mkdir -p "$dir/$(dirname "$fname")"
    printf '%b' "${spec#*=}" > "$dir/$fname"
    chmod +x "$dir/$fname"
  done <<EXECS
$(sed -n 's/^# exec //p' "$play")
EXECS
  open=$(sed -n 's/^# open \(.*\)$/\1/p' "$play")
  # "# args ...": more arguments for pad; @ROOT@ is this repository.
  extra=$(sed -n 's/^# args \(.*\)$/\1/p' "$play" | sed "s|@ROOT@|$ROOT|g")
  # shellcheck disable=SC2086
  (cd "$dir" && "$PAD" $open $extra --play "$play" --frames "$frames" --shot "$shot") > "$TMP/out" 2>&1
  status=$?
  problems=""
  [ "$status" -eq 0 ] || problems="exit status $status"
  while IFS= read -r want; do
    [ -z "$want" ] && continue
    grep -qF -- "$want" "$TMP/out" || problems="$problems${problems:+; }missing '$want'"
  done <<EXPECT
$(sed -n 's/^# expect //p' "$play")
EXPECT
  while IFS= read -r unwanted; do
    [ -z "$unwanted" ] && continue
    grep -qF -- "$unwanted" "$TMP/out" && problems="$problems${problems:+; }unwanted '$unwanted'"
  done <<ABSENT
$(sed -n 's/^# absent //p' "$play")
ABSENT
  # "# file name=text": a file's contents after the run.
  while IFS= read -r spec; do
    [ -z "$spec" ] && continue
    fname=${spec%%=*}
    printf '%b' "${spec#*=}" > "$TMP/want"
    cmp -s "$TMP/want" "$dir/$fname" || problems="$problems${problems:+; }file $fname is not what it should be"
  done <<FILECHECK
$(sed -n 's/^# file //p' "$play")
FILECHECK
  while IFS= read -r spec; do
    [ -z "$spec" ] && continue
    want=${spec##* }
    box=${spec% *}
    got=$(python3 "$HERE/../../tools/pixels.py" "$shot" $box)
    case "$want" in
      none) [ "$got" = 0 ] || problems="$problems${problems:+; }pixels $box: counted $got, wanted none" ;;
      some) [ "$got" -gt 0 ] || problems="$problems${problems:+; }pixels $box: counted none, wanted some" ;;
      *)    [ "$got" = "$want" ] || problems="$problems${problems:+; }pixels $spec: counted $got" ;;
    esac
  done <<PIXELS
$(sed -n 's/^# pixels //p' "$play")
PIXELS
  if [ -z "$problems" ]; then
    printf '  %-26s ok\n' "$name"
  else
    printf '  %-26s FAIL: %s\n' "$name" "$problems"
    sed 's/^/      | /' "$TMP/out"
    failed=$((failed + 1))
  fi
done
if [ "$failed" -eq 0 ]; then
  echo "all $total pad play tests passed"
else
  echo "$failed of $total pad play tests failed"
  exit 1
fi
