#!/usr/bin/env bats

load test_helper

@test "Call php-band to download an invalid version" {
    run bin/php-band --download 10.20
    assert_failure "The version format is not valid"
    assert_status 1
}

@test "Call php-band to download a valid version but no existing PHP" {
    run bin/php-band --download 10.10.20
    assert_line_contains "Unable to download PHP source"
    assert_status 2
    [ ! -f arch/php-10.10.20.tar.xz ]
}

