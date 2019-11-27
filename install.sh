#!/bin/sh
#
# Install from Github via curl piped to bash:
#
#   curl https://raw.githubusercontent.com/mcary/cookie-cutter/master/install.sh | bash
#
# Assuptions:
# * /usr/local/bin is in $PATH
# * /usr/local/cookie-cutter doesn't exist and is writable
# * The cc-* scripts do not exist under /usr/local/bin/ yet and it is writable
# * (This usually means it assumes it is run as root and has not been run
#   before on the current VM or server.)
#

set -e

git --version || apt-get install git
git clone https://github.com/mcary/cookie-cutter.git /usr/local/cookie-cutter
for file in /usr/local/cookie-cutter/bin/cc-*; do
  ln -v -s "$file" /usr/local/bin/
done
cc-setup
