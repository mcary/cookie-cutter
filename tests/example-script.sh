#!/bin/sh

set -xe

# Don't build it if it's left over from before to save time.
# Use "vagrant destroy" or rm -rf /var/cookie-cutter to reset.
if ! [ -d /var/cookie-cutter ]; then
  cc-setup
fi
if ! [ -d /var/cookie-cutter/images/xenial ]; then
  cc-build-ubuntu-image xenial
fi
cc-build my-image my-app.ccspec .
cc-start my-container my-image echo hello world
cc-run my-container bash -c "touch test-passed"
