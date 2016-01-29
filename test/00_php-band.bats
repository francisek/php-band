#!/usr/bin/env bats

load test_helper

@test "Call php-band without argument should display usage" {
    run bin/php-band
    assert_contains "${lines[0]}" "Usage:"
    assert_status 1
}

@test "Call php-band with query help argument should display usage" {
    run bin/php-band --help
    assert_contains "${lines[0]}" "Usage:"
    assert_status 1
}

