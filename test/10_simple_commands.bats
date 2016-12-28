#!/usr/bin/env bats

load test_helper

@test "Call php-band with query version argument" {
    run bin/php-band --version
    assert_output "0.2.0" 
    assert_success
}

@test "Call php-band with query source format argument" {
    run bin/php-band --src-format
    assert_output "Source format is currently set to xz" 
    assert_success
}

@test "Call php-band with too commands should fail" {
    run bin/php-band --src-format --version
    assert_output "You must specify exactly one command" 
    assert_status 2
}

@test "List installed versions of php-band when none is installed" {
    PHP_BAND_ASSETS_DIR=$PHP_BAND_ASSETS_DIR run bin/php-band --list-installed
    assert_output ""
    assert_status 0
}

@test "List installed versions of php-band when some are installed" {
    mkdir ${PHP_BAND_ASSETS_DIR}/inst/5.6.10 ${PHP_BAND_ASSETS_DIR}/inst/5.6.2
    PHP_BAND_ASSETS_DIR=$PHP_BAND_ASSETS_DIR run bin/php-band --list-installed
    assert_output "5.6.2
5.6.10"
    assert_status 0
}

