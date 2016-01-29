#!/usr/bin/env bash
setup() {
    find archs -type f -iname "php-5.6.10.*" -exec rm {} \;
        if [ -d src/php-5.6.10 ]; then
            rm -rf src/php-5.6.10
        fi
        if [ -d inst/5.6.10 ]; then
            rm -rf inst/5.6.10
        fi
}

flunk() {
  { if [ "$#" -eq 0 ]; then cat -
    else echo "$@"
    fi
  }
  return 1
}

assert_unimplemented() {
    assert_line "Unimplemented $1"
}

assert_success() {
  if [ "$status" -ne 0 ]; then
    flunk "Command failed with exit status $status"
  elif [ "$#" -gt 0 ]; then
    assert_output "$1"
  fi
}

assert_failure() {
  if [ "$status" -eq 0 ]; then
    flunk "expected failed exit status"
  elif [ "$#" -gt 0 ]; then
    assert_output "$1"
  fi
}

assert_status() {
  if [ "$status" != "$1" ]; then
    flunk "expected exit status $1, got $status"
  fi
}

sanitize_ansi() {
    echo "$1" | sed 's/\x1b\[[0-9;]*m//g'
}

assert_equals() {
  local a=$(sanitize_ansi "$1")
  local b=$(sanitize_ansi "$2")
  if [ "$a" != "$b" ]; then
    { echo "expected: $b"
      echo "actual  : $a"
    } | flunk
  fi
}

assert_contains() {
  local a=$(sanitize_ansi "$1")
  local b=$(sanitize_ansi "$2")
  #if [[ "$a" != *"$b"* ]]; then
  if ! grep -q  "$a" <<< "$b" ; then
    { echo "expected: $a"
      echo "actual:   $b"
    } | flunk
  fi
}

assert_output() {
  local expected
  if [ $# -eq 0 ]; then expected="$(cat -)"
  else expected="$1"
  fi
  assert_equals "$expected" "$output"
}

assert_line() {
  if [ "$1" -ge 0 ] 2>/dev/null; then
    assert_equals "$2" "${lines[$1]}"
  else
    local line
    local a=$(sanitize_ansi "$1")
    for line in "${lines[@]}"; do
        line=$(sanitize_ansi "$line")
      if [ "$line" = "$a" ]; then return 0; fi
    done
    flunk "expected line \`$1'"
  fi
}

refute_line() {
  if [ "$1" -ge 0 ] 2>/dev/null; then
    local num_lines="${#lines[@]}"
    if [ "$1" -lt "$num_lines" ]; then
      flunk "output has $num_lines lines"
    fi
  else
    local line
    local a=$(sanitize_ansi "$1")
    for line in "${lines[@]}"; do
      line=$(sanitize_ansi "$line")
      if [ "$line" = "$a" ]; then
        flunk "expected to not find line \`$line'"
      fi
    done
  fi
}

assert_line_contains() {
  if [ "$1" -ge 0 ] 2>/dev/null; then
    assert_contains "$2" "${lines[$1]}"
  else
    local line
    local a=$(sanitize_ansi "$1")
    for line in "${lines[@]}"; do
      line=$(sanitize_ansi "$line")
      if ! grep -q "$a" <<< "$line"; then 
          return 0; 
      fi
    done
    flunk "expected line containing \`$a'"
  fi
}
