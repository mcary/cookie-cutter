# Cookie-Cutter

Cookie-Cutter is a toolkit for building and running isolated application
environments.

## Installing

Install via curl-bash command as described in [install.sh].

[install.sh]:https://github.com/mcary/cookie-cutter/blob/master/install.sh

## Quick Start

As root:
```
# cc-setup
# cc-build-ubuntu-image xenial
# cc-build my-image my-app.ccspec build-context/
# cc-run --name my-container my-image echo hello world
# cc-run --rm my-image bash -l
# cc-boot --rm my-image-with-dbus -M my-container
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
mainly on the classic chroot technology, so by comparision, Cookie-Cutter:

* Works on 32-bit machines where small applications can run with a smaller memory footprint
* Does not require a daemon to run in the background
* Allows standard tools to build, manipulate, and backup filesystems
* Provides less resource isolation for networking, users, and IPC [1]

While Cookie-Cutter does provide some security benefits for applications
(assuming they run as non-root users), the main motivation is to allow an
application to dictate what gets `apt-get install`-ed without having to
give it an entire cloud VM (and pay for it).  So its sweet spot is smaller
applications running on a low budget.

Cookie-Cutter supports building standard Ubuntu images with debootstrap and
custom images from a Dockerfile-like specification.  Images can be used to
create running containers in a matter of seconds, and these containers can
persist and be started and stopped as needed.

[1] Note that cc-boot uses systemd-nspawn instead of chroot, which supports
these namespace isolations (see below)

## Commands

* `cc-build` - Build custom images from a Dockerfile-like specification
* `cc-build-ubuntu-image` - Build standard Ubuntu images from debootstrap
* `cc-setup` - Setup the directory structure that will be assumed by
  Cookie-Cutter (run this once to install Cookie-Cutter)
* `cc-run` - Create a container from an image and then run a command in it
* `cc-exec` - Run a command in an existing container
* `cc-boot` - Bootstrap a full init process in a container

Currently all these commands require root privileges.  Run them with
"--help" for more details.

## Booting a VM in a container

Instead of running a single process or command inside a container, the
`cc-boot` command invokes a full init process.  This can be useful when
running a suite of services that were designed to coexist on a single VM,
such as an SMTP server, a mail delivery agent, and an IMAP server.

Instead of chroot, `cc-boot` uses `systemd-nspawn` for isolation.  By
default, it isolates the PID namespace of the container so that `top` shows
only contained processes.  It also allows for container-scoped memory, CPU,
and other limits, and provides an isolated /proc filesystem.  It registers
the container with `machinectl`.  You can get a login prompt with
`machinectl login <name>`, or if dbus is installed in the container, you
can get a root shell with `machinectl shell <name>`.  Use `systemd-cgtop`
to see resource usage by booted container.

The `cc-boot` command supports a `-v` (`--volume`) flag to bind-mount host
filesystems into the container.

On Ubuntu, `systemd-nspawn` is installed via the `systemd-container`
package on the host.  The `systemd` package must be installed _inside_ the
container as well, for example using `cc-build`'s RUN command.
Additionally installing `dbus` inside the container will allow `machinectl`
on the host to start a root shell in the container.

For example:

 RUN apt-get update -yqq && \
   DEBIAN_FRONTEND=noninteractive apt-get install -yqq --no-install-recommends \
   systemd \
   dbus

If you are only using `cc-run` with chroot-style isolation, there is no
need to install `systemd-container` or `dbus`.

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

## Developing

* Install Vagrant
* Run `tests/run-in-vagrant`

Some slow stages (cc-setup, cc-build-ubuntu-image) will be skipped on
subsequent runs until you run `vagrant
destroy`.
