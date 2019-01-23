# Cookie-Cutter

Cookie-Cutter is a toolkit for building and running isolated application
environments.

## Quick Start

As root:
```
# cc-setup
# cc-build-ubuntu-image xenial
# cc-build my-image xenial my-app.ccspec
# cc-start my-container my-image echo hello world
# cc-run my-container my-image bash -l
```

my-app.ccspec:
```
FROM xenial
RUN apt-get update
RUN apt-get install some-package
COPY . /srv/my-app
```

## Overview

While inspired by [Twelve Factor](12factor.net) and Docker, it is built
only on the classic chroot technology, so by comparision, Cookie-Cutter:

* Works on 32-bit machines where small applications can run with a smaller memory footprint
* Does not require a daemon to run in the background
* Allows standard tools to build, manipulate, and backup filesystems
* Provides less resource isolation for networking, users, and IPC

While Cookie-Cutter does provide some security benefits for applications
(assuming they run as non-root users), the main motivation is to allow an
application to dictate what gets `apt-get install`-ed without having to
give it an entire cloud VM (and pay for it).  So its sweet spot is smaller
applications running on a low budget.

Cookie-Cutter supports building standard Ubuntu images with debootstrap and
custom images from a Dockerfile-like specification.  Images can be used to
create running containers in a matter of seconds, and these containers can
persist and be started and stopped as needed.

## Commands

* `cc-build` - Build custom images from a Dockerfile-like specification
* `cc-build-ubuntu-image` - Build standard Ubuntu images from debootstrap
* `cc-run` - Run a command in an existing container
* `cc-setup` - Setup the directory structure that will be assumed by
  Cookie-Cutter (run this once to install Cookie-Cutter)
* `cc-start` - Create a container from an image and then run a command in
  it

Currently all these commands require root privileges.  Run them with
"--help" for more details.

## Status

* This is a proof-of-concept.

* Do not run untrusted spec files.  Commands within them run as root and
  therefore can escape the chroot jail.  In addition, no effort is made to
  ensure that operations such as COPY are restricted to proper
  subdirectories of the source directory.

* As the chroot jail technology can be escaped by an attacker, do not rely
  on it to contain untrusted code.  For example, do not run apps of
  different clients on the same VM.  Also, chroot jails provide almost no
  protection for applications running as root.
