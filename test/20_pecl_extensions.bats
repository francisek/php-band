#!/usr/bin/env bats

load test_helper

setup() {
  source $BATS_TEST_DIRNAME/../lib/core.sh
}

@test "Install a single extension" {
  local output
  php_band_php_install_dir="${BATS_TEST_DIRNAME}/mock"
  output=$(php_band_pecl_build_extension 'test')
  assert_contains "Building pecl extension test" "$output"
  assert_contains "Extension building failed" "$output"
}

@test "Request installation of a pecl extension" {
  local input='n\n'
  local output
  php_band_php_install_dir="${BATS_TEST_DIRNAME}/mock"
  php_band_pecl_add_package 'test' "$input"
  assert_equals "$input" "${PHP_BAND_CUSTOM_PECL_EXTENSIONS[test]}"
}


