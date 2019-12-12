clean_old_tmp_containers () {
  rm -rf /var/cookie-cutter/containers/tmp.*
}

expect_no_tmp_containers () {
  expect_equal "$(ls /var/cookie-cutter/containers/ | grep -c '^tmp\.*')" "0" \
    "Count of tmp.* containers"
}
