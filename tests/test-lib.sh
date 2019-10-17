test_failure_count=0
test_success_count=0

test_description () {
  local name="$1"
  echo -n "Test: $name "
  check_failure_count=0
  check_success_count=0
}

expect_file_exists () {
  file="$1"
  if ! [ -f "$file" ]; then
    fail_check "Missing file: $file"
  else
    pass_check
  fi
}

expect_dir_exists () {
  dir="$1"
  if ! [ -d "$dir" ]; then
    fail_check "Missing directory: $dir"
  else
    pass_check
  fi
}

expect_success () {
  local code="$1"
  eval "$code"
  status=$?
  if [ "x$status" != "x0" ]; then
    fail_check "Command failed: $(echo "$code" | sed 's/^/  /')"
  else
    pass_check
  fi
}

expect_equal () {
  local actual="$1"
  local expected="$2"
  local description="$3"
  if [ -z "$description" ]; then
    description="this"
  fi
  if [ "x$expected" = "x$actual" ]; then
    pass_check
  else
    fail_check "Expected $description to equal [$expected], got [$actual]"
  fi
}

fail_check () {
  local msg="$1"
  echo
  echo "Failure: $msg"
  let 'check_failure_count++'
  return 1
}

pass_check () {
  let 'check_success_count++'
  echo -n "."
}

test_done () {
  let 'check_total_count = check_failure_count + check_success_count'
  echo " $check_success_count / $check_total_count passed"
  if [ "x$check_success_count" = "x$check_total_count" ]; then
    let 'test_success_count ++'
  else
    let 'test_failure_count ++'
  fi
}

summarize_tests () {
  echo
  echo "Tests failed: $test_failure_count"
  echo "Tests passed: $test_success_count"
  [ "x$test_failure_count" = "x0" ]
}

format_output () {
  status_file="exit-status.$$"
  echo
  {
    echo "Output from: $1"
    eval "$1" 2>&1
    echo "$?" > "$status_file"
  } | sed 's/^/  /'
  status="$(cat "$status_file")"
  rm "$status_file"
  return "$status"
}
