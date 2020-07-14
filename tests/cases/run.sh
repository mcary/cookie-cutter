expect_dir_not_mounted () {
  local dir="$1"
  if mount | cut -d" " -f2-3 | grep -qx "on $dir"; then
    fail_check "Directory is a mount point: $dir"
  else
    pass_check
  fi
}

test_description "'cc-run --rm' runs command"

expect_success "cc-run --rm xenial echo 'Hello World' > tmp.out"
expect_equal "$(cat tmp.out)" "Hello World" "container output"

test_done


test_description "'cc-run my-container' leaves container, unmounted"

container_dir="/var/cookie-cutter/containers/my-container"
cc-umount "my-container" || return
rm -rf --one-file-system "$container_dir" || return
#rm -f tmp.out tmp.err
[ -d some-directory ] || mkdir some-directory

expect_success "cc-run \
  -v `pwd`/some-directory:/inside-directory \
  my-container xenial \
  test -d /inside-directory"
expect_dir_exists "$container_dir"
expect_dir_not_mounted "$container_dir/filesystem"
expect_dir_not_mounted "$container_dir/filesystem/inside-directory"

rmdir some-directory

test_done


test_description "'cc-run --rm' removes container on success"

clean_old_tmp_containers

expect_success "cc-run --rm xenial true"
expect_no_tmp_containers

test_done


test_description "'cc-run --rm' removes container on failure"

clean_old_tmp_containers

expect_failure "cc-run --rm xenial false"
expect_equal "$(ls /var/cookie-cutter/containers/ | grep -c '^tmp\.*')" "0" \
  "Count of tmp.* containers"

test_done


test_description "'cc-run --rm' removes container on missing image"

clean_old_tmp_containers

expect_failure "cc-run --rm non-existent-image true 2> tmp.err"
expect_no_tmp_containers
expect_equal "$(cat tmp.err)" "Image not found: non-existent-image" "error"

test_done
