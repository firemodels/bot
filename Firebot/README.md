# Firebot: A Continuous Integration Tool for FDS

Firebot is a verification script that can be run at regular intervals as part of a continuous integration program. At NIST, this script is run by a pseudo-user named `firebot` on a linux cluster each night. The pseudo-user `firebot` clones the various repositories in the GitHub project named `firemodels`, builds FDS and Smokeview, runs the verification cases, checks the results for accuracy, and builds all of the manuals. The entire process takes a few hours to complete.

## Set-Up

The following steps need only be done once. The exact phrasing of the commands are for the NIST linux cluster named blaze. You might need to modify the path and module names.

1. Clone the bot repository included in the GitHub organization named `firemodels`.  Other repositories needed by firebot will be cloned by firebot.

2. Ensure that the following software packages are installed on the system:

    * Intel Fortran and C compilers, Intel MPI, Intel Inspector
    * Gnu Fortran compiler (Optional)
    * LaTeX (TeX Live distribution), be sure to make this the default LaTeX in the system-wide PATH
    * Matlab (test the command `matlab`)

3. Firebot uses email notifications for build status updates. Ensure that outbound emails can be sent using the `mail` command.

4. Install libraries for Smokeview. On CentOS, you can use the following command:
   ```
   yum install mesa-libGL-devel mesa-libGLU-devel libXmu-devel libXi-devel xorg-x11-server-Xvfb
   ```

5. Add lines to your `~/.bashrc` file to define the compiler environment.  For tthe Intel oneAPI compilers we use:
    ```
source /opt/intel/oneapi/setvars.sh >& /dev/null
# - needed to build smokeview
export IFORT_COMPILER_LIB=/opt/intel/oneapi/compiler/latest/linux/compiler/lib/intel64_lin
    ulimit -s unlimited
    ```

6. Setup passwordless SSH for the your account. Generate SSH keys and ensure that the head node can SSH into all of the compute nodes. Also, make sure that your account information is propagated across all compute nodes.

7. Ensure that a queue named `firebot` is created and enabled. Test the `qstat` command.  If you use some other queue say batch then use `-q batch` when running firebot.

8. By default, firebot sends email to the email address configured for your bot repo (output of command `git config user.email` ) .  If you wish email to go to different email addresses, create a file named $HOME/.firebot/firebot_email_list.sh for some `user1` and `user2` (or more) that looks like:

   ```
   #!/bin/bash
   mailToFDS="user1@host1.com, user2@host2.com"
   ```

## Running firebot

The script `firebot.sh` is run using the wrapper script `run_firebot.sh`. This script uses a locking file that ensures multiple instances of firebot do not run at the same time, which would cause file conflicts. To see the various options associated with running firebot, type
```
./run_firebot.sh -H
```

A typical way to run firebot is to cd into the directory containing firbot.sh and type: 

``` nohup ./run_firebot.sh -c -u -J -q firebot -R master -m user@host.com &```

The `-c` and `-u` options clean and update the bot respectively. The `-J` option directs Firebot to use the Intel compilers. The email addressee specified by the -m option receives a notice when Firebot is done. The -R master option causes fds, smv and other repos used by firebot to be cloned and checked out using the master branch.  The `nohup` at the start and `&` at the end of the command run `firebot.sh` in the background and redirect screen output to the file called `nohup.out`.

Note, firebot clones the repos it uses so not be used in repos where you are doing work.  You should run firebot in a fresh repo.  You can however run firebot without cloning repos by NOT specifying the -R master option.  In this case, firebot will update and clean repos (if you have specifeid the -u and -c options).

To kill firebot, cd to the directory containing firebot.sh and type:

```./run_firebot.sh -k```

Important things to consider: do you want to test your own local changes, or update your repositories from the central repository? Do you want to use Intel MPI or Open MPI? Do you want to skip certain stages of the process?

You can run firebot regularly using a `crontab` file by adding an entry like the following using the `crontab -e` command:
```
PATH=/bin:/usr/bin:/usr/local/bin:/home/<username>/firemodels/bot/Firebot:$PATH
MAILTO=""
# Run firebot at 9:56 PM every night
56 21 * * * cd ~/<username>/firemodels/bot/Firebot ; bash -lc "./run_firebot.sh <options>"
```

The output from firebot is written into the directory called `output` which is in the same directory as the `firebot.sh` script itself. When firebot completes, email should be sent to the specified list of addresses. The fds/Manuals directory in the fds repo containing manuals and figures is copied to the directdory $HOME/.firebot/Manuals .
