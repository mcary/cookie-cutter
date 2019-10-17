test_description 'run example-script.sh'

container_dir=/var/cookie-cutter/containers/my-container/
cc-umount "my-container"
rm -rf "$container_dir"

expect_success 'format_output "sh -x ./example-script.sh"'

expect_file_exists "$container_dir/filesystem/test-passed"
expect_file_exists "$container_dir/filesystem/srv/my-app/example-script.sh"

test_done
