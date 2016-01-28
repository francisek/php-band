#/usr/bin/env bash

test_version_major=${1}
test_version_minor=${2}
test_version_patch=${3}
test_version_addon=${4}

test_main="test_main"
test_major="$test_main $test_version_major"
test_minor="$test_main $test_version_minor"
test_patch="$test_main $test_version_patch"
test_addon="$test_main $test_version_addon"
