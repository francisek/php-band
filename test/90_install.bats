#!/usr/bin/env bats

load test_helper

@test "Call php-band to install an already downloaded archive" {
#    [ ! -f "archs/php-5.6.10.tar.xz" ]
#    cp $BATS_TEST_DIRNAME/fixtures/php-5.6.10.tar.xz archs/
    [ -f "${PHP_BAND_ASSETS_DIR}/archs/php-5.6.10.tar.xz" ]
    PHP_BAND_ASSETS_DIR=$PHP_BAND_ASSETS_DIR run bin/php-band --install 5.6.10
    [ -f "${PHP_BAND_ASSETS_DIR}/archs/php-5.6.10.tar.xz" ]
    [ -d "${PHP_BAND_ASSETS_DIR}/src/php-5.6.10" ]
    [ -f "${PHP_BAND_ASSETS_DIR}/src/php-5.6.10/.configured" ]
    [ -f "${PHP_BAND_ASSETS_DIR}/src/php-5.6.10/.built" ]
    [ -f "${PHP_BAND_ASSETS_DIR}/inst/5.6.10/test" ]
}

@test "Call php-band to install a valid version of an existing PHP" {
    if [ "x$PHP_BAND_TEST_COMPILATION" = "x" ]; then
        skip "We only compile if PHP_BAND_TEST_COMPILATION is set"
    fi
    PHP_BAND_ASSETS_DIR=$PHP_BAND_ASSETS_DIR run bin/php-band --install 5.6.10
    assert_line_contains "PHP 5.6.10 has been downloaded"
    [ -f "archs/php-5.6.10.tar.xz" ]
    [ -d "src/php-5.6.10" ]
    [ -f "src/php-5.6.10/.configured" ]
    [ -f "src/php-5.6.10/.built" ]
    [ -f "inst/5.6.10/bin/php" ]
    assert_status 0
    run ${PHP_BAND_ASSETS_DIR}/inst/5.6.10/bin/php -v
    assert_line_contains "php 5.6.10"
    assert_status 0
}

