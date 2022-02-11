# Revbot: Scripts for testing fds by building and running it for many repo revisons

## revbot.sh 

### Usage

revbot.sh [options] [casename.fds]

revbot.sh builds fds for a set of revisions found in a revision file.
It then runs casename.fds for each fds that was built. If casename.fds
was not specified then only the fdss are built. The revision file
is generated using the script get_revisions.sh.  git checkout revisions
are performed on a copy of the fds repo cloned by this script.  So revbot.sh
will not effect the fds repo you normally work with.

### Options

```
 -d dir - root directory where fdss are built [default: ...bot/Revbot/TESTDIR]
 -f   - force cloning of the fds_test repo
 -F   - use existing fds_test repo
 -m email_address - send results to email_address [default: gforney@gmail.com]
 -N n - specify maximum number of fdss to build [default: 10]
 -n n - number of MPI processes per node used when running cases [default: 1]
 -p p - number of MPI processes used when runnng cases [default: 1]
 -r revfile - file containing list of revisions used to build fds 
              [default: revisions.txt]
              The revfile is built by the get_revisions.sh script
 -h   - show this message
 -q q - name of batch queue used to build fdss and to run cases. [default: batch]
 -s   - skip the build step (fdss were built eariler)
 -T type - build fds using type dv (impi_intel_linux_64_dv) or 
           type db (impi_intel_linux_64_db) makefile entries. If -T is not
           specified then fds is built using the release
           (impi_intel_linux_64) makefile entry.
```

## get_revisions.sh

### Usage

get_revisions.sh [options]
get_revisions.sh generates a list of fds revisions from
bewteen optionally specified dates.  The file generated
is used by the script revbot.sh to build and run multiple
versions of fds, one version for each repo revision

### Options

```
 -a date - include revisions after date [default: 10-Nov-2021 (3 months before current date)]
 -b date - include revisions before date [default: 10-Feb-2022 (current date)]
 -n n    - maximum number of revisions to include [default: 10]
 -h      - show this message
 -r revs - file containing revisions used to build fds [default: revisions.txt]
 ```
