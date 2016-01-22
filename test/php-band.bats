#!/usr/bin/env bats

load test_helper

@test "Call php-band without argument should display usage" {
    run bin/php-band
    assert_status 1
    assert_contains "${lines[0]}" "Usage:"
}

@test "Call php-band with query help argument should display usage" {
    run bin/php-band --help
    assert_status 1
    assert_contains "${lines[0]}" "Usage:"
}

@test "Call php-band with query version argument" {
    run bin/php-band --version
    assert_success
    assert_output "0.0.1" 
}

@test "Call php-band to install an invalid version" {
    run bin/php-band --install 10.20
    assert_status 1
    assert_failure "The version format is not valid"
}

@test "Call php-band to install a valid version but no existing PHP" {
    run bin/php-band --install 10.10.20
    assert_status 1
    assert_line_contains "Unable to download PHP source"
}

@test "Call php-band to install a valid version of an existing PHP" {
    run bin/php-band --install 5.6.10
    assert_status 0
    assert_line_contains "PHP 5.6.10 has been downloaded"
}


