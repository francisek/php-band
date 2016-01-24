#!/usr/bin/env bats

load test_helper

@test "Call php-band with query version argument" {
    run bin/php-band --version
    assert_output "0.0.1" 
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

