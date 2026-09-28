#!/bin/sh
# Show the semantic-analysis / code-generation error for one test program.
W=$(mktemp -d)
../catmint-lex/bin/catmint-parser "$1" "$W/t.ast" >"$W/parse.log" 2>&1
( cd "$W" && "$OLDPWD/bin/catmint-gen" t.ast t.sem >out.log 2>err.log )
echo "exit=$?"
cat "$W/err.log"
