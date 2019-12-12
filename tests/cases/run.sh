test_description "'cc-run --rm' runs command"

expect_success "cc-run --rm xenial echo 'Hello World' > tmp.out"
expect_equal "$(cat tmp.out)" "Hello World" "container output"

test_done


test_description "'cc-run my-container' leaves container"

container_dir="/var/cookie-cutter/containers/my-container"
cc-umount "my-container" || return
rm -rf "$container_dir" || return

expect_success "cc-run my-container xenial true"
expect_dir_exists "$container_dir"

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
