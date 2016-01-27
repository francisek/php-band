#!/usr/bin/env bash

load test_helper

setup() {
    source $BATS_TEST_DIRNAME/../lib/core.sh
}

@test "Error exit status" {
    local ret=$(error_exit "Custom error message" 3)
    assert_equals "$ret" "Custom error message"
}

@test "Parsing a valid version number" {
    local php_version_major
    local php_version_minor
    local php_version_patch
    local php_version_addon
    parse_version "10.20.30RC1"
    assert_equals "$php_version_major" "10"
    assert_equals "$php_version_minor" "20"
    assert_equals "$php_version_patch" "30"
    assert_equals "$php_version_addon" "RC1"
}

@test "Apply shell extension into variable" {
    local str='$hello $world'
    local hello='Hello'
    local world='World'
    local res=$(apply_shell_expansion "$str")
    [ "$res" != "$str" ]
    [ "$res" = "Hello World" ]
}
