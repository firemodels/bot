# CFASTbot: A Continuous Integration Tool for CFAST

CFASTbot is a script that can be run at a regular intervals as part of a continuous integration program. At NIST, the script is run by a pseudo-user named `firebot` on a linux cluster each time the source code is touched. The pseudo-user `firebot` updates the various repositories in the GitHub project named `firemodels`, compiles CFAST and Smokeview, runs the validation and verification cases, checks the results for accuracy, and builds all of the manuals. The entire process takes about 20 minutes to complete.

## Set-Up

The following steps need only be done once. You might need to modify the path and module names.

1. If you do not want CFASTbot to clone repositories for you, you must clone the repositories that are included in the GitHub organization called `firemodels`: `cfast`, `fds`, `smv`, `bot`, and `exp`.

2. Ensure that the following software packages are installed on the system:

    * Intel Fortran and C compilers
    * Slurm queuing system
    * LaTeX (TeX Live distribution), be sure to make this the default LaTeX in the system-wide PATH
    * Python (test by issuing the command `python`)

3. CFASTbot uses email notifications for build status updates. Ensure that outbound emails can be sent using the `mail` command.

4. Install libraries for Smokeview. On CentOS, you can use the following command:
   ```
   yum install mesa-libGL-devel mesa-libGLU-devel libXmu-devel libXi-devel xorg-x11-server-Xvfb
   ```

5. Ensure that the Intel Fortran compiler is active. For example, type `ifx --version` at the command prompt.  

6. By default, CFASTbot sends email to the email address configured for your bot repo (output of command `git config user.email` ) .  If you wish email to go to different email addresses, create a file named $HOME/.cfastbot/cfastbot_email_list.sh for some `user1` and `user2` (or more) that looks like:
   ```
   #!/bin/bash
   mailToFCFAST="user1@host1.com, user2@host2.com"
   ```

## Running CFASTbot

The script `cfastbot.sh` is run using the wrapper script `run_cfastbot.sh`. This script uses a semaphore file that ensures multiple instances of CFASTbot do not run, which would cause file conflicts. To see the various options associated with running CFASTbot, type
```
./run_cfastbot.sh -h
```
Important things to consider: do you want to test your own local changes, or update your repositories from the central repository? Do you want to skip certain stages of the process?

If you just want to test your local versions of `cfast`, `smv`, and `exp`, issue the following command from within the `Cfastbot` directory of the `bot` repository:
```
nohup ./run_cfastbot.sh -q <queue> -m <email address> &
```
You can start CFASTbot at some future time using `crontab` with an entry like the following:
```
PATH=/bin:/usr/bin:/usr/local/bin:/home/<username>/firemodels/bot/Cfastbot:$PATH
MAILTO=""
# Run cfastbot at 9:56 PM every night
56 21 * * * cd ~/<username>/firemodels/bot/Cfastbot ; bash -lc "./run_cfastbot.sh <options>"
```
The output from CFASTbot is written into the directory called `output` which is in the same directory as the `cfastbot.sh` script itself. When cfastbot completes, email should be sent to the specified list of addresses.
