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

perform_build_with_file () {
  local build_context="${1-.}"
  cat > tmp.cc-build
  expect_success "cc-build '$new_image_name' tmp.cc-build $build_context"
  rm -f tmp.cc-build
}

attempt_build_with_file () {
  cat > tmp.cc-build
  expect_failure "cc-build '$new_image_name' tmp.cc-build . 2> tmp.err"
  rm -f tmp.cc-build
}


test_description "FROM creates an image"

setup
perform_build_with_file <<-EOF
FROM xenial
EOF

expect_build_complete
expect_equal "$(ls "$new_image/diff" | grep -c '.')" "0" "file count of layer"
expect_equal "$(cat "$new_image/from")" "xenial" "'from' image"

test_done


test_description "FROM raises error for invalid name"

setup
attempt_build_with_file <<-EOF
FROM non-existent-image
EOF

expect_cleanup_happened
expect_failure "test -d '$new_image'"

expect_equal "$(cat tmp.err)" "Image not found: non-existent-image" "error"

test_done


test_description "COPY adds file"

setup
rm -f a-file-to-add
echo some-contents > a-file-to-add

perform_build_with_file <<-EOF
FROM xenial
COPY a-file-to-add
EOF

expect_build_complete
expect_equal "$(cat "$new_image/diff/a-file-to-add")" "some-contents" \
  "contents of a-file-to-add"

test_done


test_description "COPY adds directory"

setup
rm -rf a-dir
mkdir a-dir
echo some-contents > a-dir/a-file-to-add

perform_build_with_file <<-EOF
FROM xenial
COPY a-dir
EOF

expect_build_complete
expect_equal "$(cat "$new_image/diff/a-dir/a-file-to-add")" "some-contents" \
  "contents of a-dir/a-file-to-add"

test_done


test_description "COPY relative build context"

setup
rm -rf a-dir
mkdir a-dir
echo some-contents > a-dir/a-file-to-add

perform_build_with_file a-dir <<-EOF
FROM xenial
COPY .
EOF

expect_build_complete
expect_equal "$(cat "$new_image/diff/a-file-to-add")" "some-contents" \
  "contents of a-file-to-add"

test_done


test_description "COPY relative target"

setup
rm -f a-file-to-add
echo some-contents > a-file-to-add

perform_build_with_file <<-EOF
FROM xenial
RUN mkdir a-dir/
COPY a-file-to-add a-dir/
EOF

expect_build_complete
expect_equal "$(cat "$new_image/diff/a-dir/a-file-to-add")" "some-contents" \
  "contents of a-file-to-add"

test_done


test_description "RUN runs command"

setup

perform_build_with_file <<-EOF
FROM xenial
RUN touch the-command-ran
EOF

expect_build_complete
expect_file_exists "$new_image/diff/the-command-ran"

test_done


test_description "RUN command fails"

setup

attempt_build_with_file <<-EOF
FROM xenial
RUN false
EOF

expect_cleanup_happened
expect_equal "$(cat tmp.err)" "Error running: false  " "error"

test_done
