wait_for_boot_and_shutdown () {
  local pid="$1"
  local cmd="$2"
  # Wait for boot to complete:
  (tail -n+0 -f tmp.out & ) | grep -q "^Ubuntu .* console" # wait for boot
  [ x"$?" = x"0" ] || fail_check "Not booted successfully."
  [ -n "$cmd" ] && eval "$cmd"
  # "kill -- -$pid" means kill the process group lead by $pid
  kill -INT -- -$pid
  for i in `seq 1 50`; do
    echo -n ,
    kill -0 $pid 2> /dev/null || break
    sleep 0.1
  done
}


test_description "'cc-boot --rm' boots"

clean_old_tmp_containers
rm -f tmp.out tmp.err

setsid cc-boot --rm xenial > tmp.out 2> tmp.err &
wait_for_boot_and_shutdown $!

expect_success "$(grep -q ' login:' tmp.out)"
# These messages were fixed by https://github.com/systemd/systemd/pull/3748
# in 2017:
#
#   Failed to create directory /var/cookie-cutter/containers/tmp.6616/filesystem/sys/fs/selinux: Read-only file system
#
# Watch to notice when it stops.
expect_success "$(grep -q '/sys/fs/selinux: Read-only file system' tmp.err)"
expect_equal "$(grep -vE '/selinux:|Trying to halt' tmp.err | wc -l)" "0" \
  "Non-selinux non-halting stderr"
expect_no_tmp_containers

# Avoid file truncation error by renaming the old tmp.out in case "tail"
# is still following it
( mv tmp.out tmp.out.$$.tail.old)

test_done


test_description "'cc-boot my-container' leaves container, unmounted"

container_dir="/var/cookie-cutter/containers/my-container"
cc-umount "my-container" || return
rm -rf --one-file-system "$container_dir" || return
rm -f tmp.out tmp.err
[ -d some-directory ] || mkdir some-directory

# Also check extra flags to nspawn like "-M" in the same test
# because these cases are so expensive.
setsid cc-boot \
  -v `pwd`/some-directory:/inside-directory \
  my-container xenial \
  -M 'machine-name' > tmp.out 2> tmp.err &
grep Ubuntu tmp.out
wait_for_boot_and_shutdown $! '
  expect_success "machinectl status machine-name > /dev/null"
  expect_success "mount |
    grep -q \" on $container_dir/filesystem/inside-directory\""
'

expect_dir_exists "$container_dir"
expect_dir_not_mounted "$container_dir/filesystem/inside-directory"
expect_dir_not_mounted "$container_dir/filesystem"

rmdir some-directory
# Avoid file truncation error by renaming the old tmp.out in case "tail"
# is still following it
( mv tmp.out tmp.out.$$.tail.old)

test_done
