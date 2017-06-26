# MakeMKV Self-Contained Version Builder

This builder produces a tarball containing all files and dependencies needed to
run MakeMKV (both the GUI and CLI).  The only required dependency is the
presence of a X server on the same machine.

MakeMKV for Linux has 2 components:
  - The CLI, distributed as a binary built from private source code.
  - The GUI, for which source code is available.

Because the distributed binary is built againt GLIBC, MakeMKV cannot be executed
easily on distributions like Alpine Linux, where `musl` libc implementation is
used.

This self-contained version allows running MakeMKV on most Linux distributions,
event on Alpine Linux.

## Building

The build the package, simply run the `run.sh` script, without any argument.

The build is done inside a Docker container.  Thus, Docker must be installed on
your system.

At the end, `makemkv.tar.gz` will be produced in the same directory as the
script.
