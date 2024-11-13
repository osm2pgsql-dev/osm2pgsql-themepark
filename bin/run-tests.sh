#!/bin/sh

for test in tests/test-*.lua; do
    lua "$test"
done

