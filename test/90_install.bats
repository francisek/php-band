#!/usr/bin/env bats

load test_helper

@test "Call php-band to install an already downloaded archive" {
    [ ! -f "archs/php-5.6.10.tar.xz" ]
    cp $BATS_TEST_DIRNAME/fixtures/php-5.6.10.tar.xz archs/
    [ -f "archs/php-5.6.10.tar.xz" ]
    run bin/php-band --install 5.6.10
    [ -f "archs/php-5.6.10.tar.xz" ]
    [ -d "src/php-5.6.10" ]
    [ -f "src/php-5.6.10/.configured" ]
    [ -f "src/php-5.6.10/.built" ]
    [ -f "inst/5.6.10/test" ]
}

@test "Call php-band to install a valid version of an existing PHP" {
    if [ "x$PHP_BAND_TEST_COMPILATION" = "x" ]; then
        skip "We only compile if PHP_BAND_TEST_COMPILATION is set"
    fi
    run bin/php-band --install 5.6.10
    assert_line_contains "PHP 5.6.10 has been downloaded"
    [ -f "archs/php-5.6.10.tar.xz" ]
    [ -d "src/php-5.6.10" ]
    [ -f "src/php-5.6.10/.configured" ]
    [ -f "src/php-5.6.10/.built" ]
    [ -f "inst/5.6.10/bin/php" ]
    assert_status 0
    run inst/5.6.10/bin/php -v
    assert_line_contains "php 5.6.10"
    assert_status 0
}

