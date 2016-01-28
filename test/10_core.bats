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

@test "Build source filename from version parts" {
    local php_version_major='10'
    local php_version_minor='20'
    local php_version_patch='30'
    local php_version_addon='RC40'
    local src_format='xx'
    local arch_filename=$(build_source_filename)
    assert_equals "$arch_filename" "php-10.20.30RC40.tar.xx"
}

@test "Build source dirname from php version" {
    local php_version_major='10'
    local php_version_minor='20'
    local php_version_patch='30'
    local php_version_addon='RC40'
    local php_src_dirname=$(build_php_src_dirname)
    assert_equals "$php_src_dirname" "php-10.20.30RC40"
}

@test "Test config per version from main config" {
    local cfg="$BATS_TEST_DIRNAME/fixtures/test-config.sh"

    get_per_version_config "$cfg" "1" "20" "30" "RC40"
    assert_equals "$test_main" "test_main"
    assert_equals "$test_major" "test_main 1"
    assert_equals "$test_minor" "test_main 20"
    assert_equals "$test_patch" "test_main 30"
    assert_equals "$test_addon" "test_main RC40"
}

@test "Test config per uncomplete version" {
    local cfg="$BATS_TEST_DIRNAME/fixtures/test-config.sh"

    get_per_version_config "$cfg" 
    assert_equals "$test_main" "test_main"
    assert_equals "$test_major" "test_main "
    assert_equals "$test_minor" "test_main "
    assert_equals "$test_patch" "test_main "
    assert_equals "$test_addon" "test_main "
}

@test "Test config per version from specific config" {
    local cfg="$BATS_TEST_DIRNAME/fixtures/test-config.sh"

    get_per_version_config "$cfg" "10" "20" "30" "RC40"
    assert_equals "$test_main" "test_main"
    assert_equals "$test_major" "test_major 10"
    assert_equals "$test_minor" "test_minor 20"
    assert_equals "$test_patch" "test_patch 30"
    assert_equals "$test_addon" "test_addon RC40"
}

