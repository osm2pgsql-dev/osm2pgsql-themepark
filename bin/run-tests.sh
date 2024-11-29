#!/bin/bash

set -euo pipefail

echo
echo "=> Running themepark tests..."
echo

for test in tests/test-*.lua; do
    echo "$test..."
    lua "$test"
done

echo
echo "=> Running theme tests..."
echo

for themedir in themes/*; do
    theme=${themedir#themes/}
    if [[ -e "themes/$theme/tests" ]]; then
        echo "$theme:"
        (cd "themes/$theme/tests";
        for atest in *; do
            echo "* $atest..."
            lua "$atest"
        done)
    fi
done

