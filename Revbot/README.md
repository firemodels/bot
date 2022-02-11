# Revbot: A script for generating fds and running a test case for many fds repo revisons

### Usage

revbot.sh [options] [casename.fds]

revbot.sh builds fds for a set of revisions found in a revision file.
It then runs casename.fds for each fds that was built. If casename.fds
was not specified then only the fdss are built. The revision file
is generated using the script get_revisions.sh.  git checkout revisions
are performed on a copy of the fds repo cloned by this script.  So revbot                                                                                       .sh
will not effect the fds repo you normally work with.

### Options

```
 -d dir - root directory where fdss are built [default: /home4/gforney/FireModel                                                                                       s_fork/bot/Revbot/TESTDIR]
 -f   - force cloning of the fds_test repo
 -F   - use existing fds_test repo
 -m email_address - send results to email_address [default: gforney@gmail.com]
 -N n - specify maximum number of fdss to build [default: 10]
 -n n - number of MPI processes per node used when running cases [default: 1]
 -p p - number of MPI processes used when runnng cases [default: 1]
 -r revfile - file containing list of revisions used to build fds [default: revi                                                                                       sions.txt]
              The revfile is built by the get_revisions.sh script
 -h   - show this message
 -q q - name of batch queue used to build fdss and to run cases. [default: batch                                                                                       ]
 -s   - skip the build step (fdss were built eariler)
 -T type - build fds using type dv (impi_intel_linux_64_dv) or type db (impi_int                                                                                       el_linux_64_db)
           makefile entries. If -T is not specified then fds is built using the                                                                                        release
           (impi_intel_linux_64) makefile entry.
```