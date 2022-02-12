# Revbot: Scripts for testing fds and smokeview

## revbot.sh 

revbot.sh [options] [casename.fds]

revbot.sh builds fds or smokeview for a set of revisions found in
a revision file. If fds was built, it also runs casename.fds for.
each fds that was built. The revision file is generated using
get_revisions.txt. git checkout revisions are performed on a
copy of the fds or smv repo cloned by this script.  So revbot.sh
does not effect the repo you normally work with.

### Commonly Used Options

```
  -h   - show commonly used options
 -H   - show all options
 -m email_address - send results to email_address
 -N n - specify maximum number of fdss or smokeviews to build [default: 10]
 -q q - name of batch queue used to build fdss and to run cases. [default: batch]
 -r repo - repo can be fds or smv. [default: fds}.  If smv the revbot.sh only builds
           smokeview, it does not run or view cases
```

### Other Options

```
 -d dir - root directory where fdss are built [default: /home/gforney/FireModels_fork/bot/Revbot/TESTDIR]
 -f   - force cloning of the fds_test repo
 -F   - use existing fds_test repo
 -n n - number of MPI processes per node used when running cases [default: 1]
 -p p - number of MPI processes used when runnng cases [default: 1]
 -r revfile - file containing list of revisions used to build fds [default: _revisions.txt]
              The revfile is built by the get_revisions.sh script
 -s   - skip the build step (fdss were built eariler)
 -T type - build fds using type dv (impi_intel_linux_64_dv) or type db (impi_intel_linux_64_db)
           makefile entries. If -T is not specified then fds is built using the release
           (impi_intel_linux_64) makefile entry.
```

## get_revisions.sh

get_revisions.sh [options]
get_revisions.sh generates a list of fds or smv revisions
committed between optionally specified dates.  The file
generated is used by the script revbot.sh to build and run
multiple versions of fds, one version for each repo
revision or to build multiple versions of smokeview


### Options

```
 -a date - include revisions after date [default: 11-Nov-2021]
 -b date - include revisions before date [default: 11-Feb-2022]
 -n n    - maximum number of revisions to include [default: 10]
 -h      - show this message
 -r repo - generate revisions for repo [default: fds]
           A list of revisions are outputted to fds_revisions.txt
 ```
 
 ## Example Usage
 
```cd ...bot/Revbot```

Generate a list of 25 revision of the fds repo between now and 3 months ago. Output these revisons to the file ```revisions.txt``` .

``` ./get_revisions.sh -n 25 ```

Run 25 versions of fds on ```casename.fds``` using the revisions in ```revisions.txt```  generated previously.  Run ```casename.fds``` using 8 processes.

```./revbot.sh -N 25 -p 8 casename.fds```
 
 Generate a list of 20 revisions commited in October of 2021.  

``` ./get_revisions.sh  -a 1-Oct-2021 -b 31-Oct-2021 -n 20 ```

Assume the fds repo was previously cloned by ```revbot.sh``` , use -F to reuse this repo. Use -T dv to run ```casename.fds``` using the dv version of fds
(build using the impi_intel_linux_64_dv makefile entry)

```./revbot -F -N 20 -T dv casename.fds```
