new_image_name="my-image"
new_image="/var/cookie-cutter/images/$new_image_name"

setup () {
  cc-umount "$new_image_name"
  rm -rf --one-file-system "$new_image"
  rm -rf --one-file-system /var/cookie-cutter/containers/tmp.*
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
  expect_equal "$(ls . | grep -c 'tmp\.\d+\.status')" "0" \
      "Count of tmp.*.status files"
}

perform_build_with_file () {
  local build_context="${1-.}"
  local default_opts="-q"
  local opts="${2-$default_opts}"
  local redirects="> tmp.out 2> tmp.err"
  cat > tmp.cc-build
  expect_success \
    "cc-build $opts '$new_image_name' tmp.cc-build $build_context $redirects"
  rm -f tmp.cc-build
}

attempt_build_with_file () {
  cat > tmp.cc-build
  local default_opts="-q"
  local opts="${1-$default_opts}"
  local redirects="> tmp.out 2> tmp.err"
  expect_failure "cc-build $opts '$new_image_name' tmp.cc-build . $redirects"
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
rm -rf --one-file-system a-dir
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
rm -rf --one-file-system a-dir
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


test_description "Without -q: indents command stdout"

perform_build_with_file . "" <<-EOF
FROM xenial
RUN echo hi
EOF

expect_cleanup_happened
expect_equal "$(cat tmp.out)" \
"
FROM xenial  

RUN echo hi 
  hi" "stdout"
expect_equal "$(cat tmp.err)" "" "stderr"

test_done


test_description "Without -q: indents command stderr"

perform_build_with_file . "" <<-EOF
FROM xenial
RUN echo hi >&2
EOF

expect_cleanup_happened
expect_equal "$(cat tmp.out)" \
"
FROM xenial  

RUN echo hi >&2" "stdout"
expect_equal "$(cat tmp.err)" "  hi" "stderr"

test_done


test_description "Without -q: preserves exit code"

attempt_build_with_file "" <<-EOF
FROM xenial
RUN false
EOF

expect_cleanup_happened
expect_equal "$(cat tmp.err)" "Error running: false  " "error"

test_done


test_description "With -d: debugs on error"

echo "echo shell is running" > tmp.shell
chmod a+x tmp.shell

SHELL="/bin/tmp.shell" attempt_build_with_file "-q -d" <<-EOF
FROM xenial
COPY tmp.shell /bin/tmp.shell
RUN false
EOF

expect_cleanup_happened
expect_equal "$(cat tmp.out)" "shell is running" "shell output"

rm tmp.shell

test_done
