#!/bin/sh

set -e

# Don't build it if it's left over from before to save time.
# Use "vagrant destroy" or rm -rf --one-file-system /var/cookie-cutter to reset.
if ! [ -d /var/cookie-cutter ]; then
  cc-setup
fi
if ! [ -d /var/cookie-cutter/images/xenial ]; then
  cc-build-ubuntu-image xenial
fi
cc-build my-image my-app.ccspec .
cc-run --rm my-image echo hello world
cc-run --name my-container my-image bash -c "touch test-passed"
