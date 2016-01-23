#!/usr/bin/env bats

load test_helper

@test "Call php-band to download an invalid version" {
    run bin/php-band --download 10.20
    assert_status 1
    assert_failure "The version format is not valid"
}

@test "Call php-band to download a valid version but no existing PHP" {
    run bin/php-band --download 10.10.20
    assert_status 1
    assert_line_contains "Unable to download PHP source"
    [ ! -f arch/php-10.10.20.tar.xz ]
}

@test "Call php-band to install a valid version of an existing PHP" {
    run bin/php-band --download 5.6.10
    assert_status 0
    assert_line_contains "PHP 5.6.10 has been downloaded"
    [ -f arch/php-5.6.10.tar.xz ]
}



