expect_path_not_mounted () {
  local dir="$1"
  if mount | cut -d" " -f2-3 | grep -qx "on $dir"; then
    fail_check "Path is a mount point: $dir"
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
mount | grep -q "$container_dir/filesystem/inside-directory" &&
  umount "$container_dir/filesystem/inside-directory"
cc-umount "my-container" || return
rm -rf --one-file-system "$container_dir" || return
#rm -f tmp.out tmp.err
[ -d some-directory ] || mkdir some-directory

expect_success "cc-run \
  -v `pwd`/some-directory:/inside-directory \
  my-container xenial \
  test -d /inside-directory"
expect_dir_exists "$container_dir"
expect_path_not_mounted "$container_dir/filesystem"
expect_path_not_mounted "$container_dir/filesystem/inside-directory"

rmdir some-directory

test_done


test_description "'cc-run my-container' unmounts after slow-exiting process"

container_dir="/var/cookie-cutter/containers/my-container"
cc-umount "my-container" || return
rm -rf --one-file-system "$container_dir" || return

# We must setsid because if we rely on killing the parent only,
# it seems to have signals blocked (a shell thing?) and the trap
# in cc-run is not invoked nor is the "sleep" call interruped.
# Anyway, most shells and init service managers will create a new
# process group and kill all the processes anyway, so this is probably
# acceptible behavior (and it seemed to happen this way before adding
# enhanced fuser cleanup...).
setsid -w cc-run \
  my-container xenial \
  sh -c 'sleep 300' > tmp.out &
container_pid="$!"

sleep 0.1
ps -A --forest -o pid,pgid,start,args > ps.out
expect_dir_exists "$container_dir"
kill -TERM -"$container_pid"
sleep 0.5
expect_path_not_mounted "$container_dir/filesystem"
echo "Waiting for container..."
wait $container_pid

test_done


test_description "'cc-run my-container' mounts a file"

container_dir="/var/cookie-cutter/containers/my-container"
mount | grep -q "$container_dir/filesystem/inside-file" &&
  umount "$container_dir/filesystem/inside-file"
cc-umount "my-container" || return
rm -rf --one-file-system "$container_dir" || return
#rm -f tmp.out tmp.err
[ -d some-file ] || echo whoa > some-file

expect_equal "$(cc-run \
  -v `pwd`/some-file:/inside-file \
  my-container xenial \
  cat /inside-file)" "whoa" "contents of /inside-file"
expect_path_not_mounted "$container_dir/filesystem"
expect_path_not_mounted "$container_dir/filesystem/inside-file"

rm some-file

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
