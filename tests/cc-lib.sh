clean_old_tmp_containers () {
  rm -rf /var/cookie-cutter/containers/tmp.*
}

expect_no_tmp_containers () {
  expect_equal "$(ls /var/cookie-cutter/containers/ | grep -c '^tmp\.*')" "0" \
    "Count of tmp.* containers"
}

expect_dir_not_mounted () {
  local dir="$1"
  if mount | cut -d" " -f2-3 | grep -qx "on $dir"; then
    fail_check "Directory is a mount point: $dir"
  else
    pass_check
  fi
}
