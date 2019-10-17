new_image_name="my-image"
new_image="/var/cookie-cutter/images/$new_image_name"

setup () {
  cc-umount "$new_image_name"
  rm -rf "$new_image"
  rm -rf /var/cookie-cutter/containers/tmp.*
}

expect_build_complete () {
  expect_cleanup_happened
  expect_dir_exists "$new_image"
}

expect_cleanup_happened () {
  local containers="/var/cookie-cutter/containers/"
  expect_equal "$(ls "$containers" | grep -c '^tmp\.*')" "0" \
    "Count of tmp.* containers"
  expect_equal "$(ls "$containers" | grep -c '^build\.*')" "0" \
      "Count of build.* containers"
}


test_description "FROM creates an image"

setup
cat > tmp.cc-build <<-EOF
FROM xenial
EOF

expect_success "cc-build '$new_image_name' tmp.cc-build ."

expect_build_complete
expect_equal "$(ls "$new_image/diff" | grep -c '.')" "0" "file count of layer"
expect_equal "$(cat "$new_image/from")" "xenial" "'from' image"

test_done


test_description "COPY adds file"

setup
rm -f a-file-to-add
echo some-contents > a-file-to-add
cat > tmp.cc-build <<-EOF
FROM xenial
COPY a-file-to-add
EOF

expect_success "cc-build '$new_image_name' tmp.cc-build ."

expect_build_complete
expect_equal "$(cat "$new_image/diff/a-file-to-add")" "some-contents" \
  "contents of a-file-to-add"

test_done


test_description "COPY adds directory"

setup
rm -rf a-dir
mkdir a-dir
echo some-contents > a-dir/a-file-to-add
cat > tmp.cc-build <<-EOF
FROM xenial
COPY a-dir
EOF

expect_success "cc-build '$new_image_name' tmp.cc-build ."

expect_build_complete
expect_equal "$(cat "$new_image/diff/a-dir/a-file-to-add")" "some-contents" \
  "contents of a-dir/a-file-to-add"

test_done


test_description "RUN runs command"

setup
cat > tmp.cc-build <<-EOF
FROM xenial
RUN touch the-command-ran
EOF

expect_success "cc-build '$new_image_name' tmp.cc-build ."

expect_build_complete
expect_file_exists "$new_image/diff/the-command-ran"

test_done


rm -f tmp.cc-build
