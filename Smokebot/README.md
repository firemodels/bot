# Smokebot: A Continuous Integration Tool for Smokeview

Smokebot is a verification test script that can be run at a regular intervals as part of a continuous integration program. At NIST, the script is run by a pseudo-user named `smokebot` on a linux cluster each night. The pseudo-user `smokebot` updates the various repositories in the GitHub project named `firemodels`, compiles FDS and Smokeview, runs the verification cases, generates smokeview images, and compiles all of the manuals. The entire process takes an hour to complete.

## Set-Up

The following steps need only be done once. The exact phrasing of the commands are for the NIST linux cluster named blaze. You might need to modify the path and module names.

1. Clone the repositories that are included in the GitHub organization called `firemodels`: `bot`, `cfast`, `fds`, `fig` and `smv`. Clone `bot` first, then cd into `bot/Scripts` and type `./setup_repos.sh -a` . This will clone all the other repos needed in the same directory as `bot` (or you can clone each repo in the same way as you cloned `bot`).

2. Ensure that the following software packages are installed on the system:

    * Intel Fortran and C compilers and Intel Inspector
    * Gnu Fortran compiler
    * LaTeX (TeX Live distribution), be sure to make this the default LaTeX in the system-wide PATH

3. smokebot uses email notifications for build status updates. Ensure that outbound emails can be sent using the `mail` command.

4. Install libraries for Smokeview. On CentOS, you can use the following command:
   ```
   yum install mesa-libGL-devel mesa-libGLU-devel libXmu-devel libXi-devel xorg-x11-server-Xvfb
   ```

5. Add the following lines to your `~/.bashrc` file:
    ```
    . /usr/local/Modules/3.2.10/init/bash
    module load null modules torque-maui
    module load intel/18
    module load gfortran492
    ulimit -s unlimited
    ```
    Note that these modules load the Intel Fortran and Gnu Fortran compilers, both of which are used to check FDS for syntax errors and consisistency with the Fortran 2008 standard.
    
6. Setup passwordless SSH for the your account. Generate SSH keys and ensure that the head node can SSH into all of the compute nodes. Also, make sure that your account information is propagated across all compute nodes.

7. Ensure that a queue named `smokebot` is created, enabled, and started in the torque queueing system and that nodes are defined for this queue. Test the `qstat` command.  If you use some other queue say batch then use `-q batch` when running smokebot.

8. By default, smokebot sends email to the email address configured for your bot repo (output of command `git config user.email` ) .  If you wish email to go to different email addresses, create a file named $HOME/.smokebot/firebot_email_list.sh for some `user1` and `user2` (or more) that looks like:

```
#!/bin/bash

# General mailing list for smokebot status report
mailToFDS="user1@host1.com, user2@host2.com"
```

## Running Smokebot

The script `smokebot.sh` is run using the wrapper script `run_smokebot.sh`. This script uses a semaphore file that ensures multiple instances of smokebot do not run, which would cause file conflicts. To see the various options associated with running smokebot, type
```
./run_smokebot.sh -H
```
Important things to consider: do you want to test your own local changes, or update your repositories from the central repository? Do you want to use Intel MPI or Open MPI? Do you want to skip certain stages of the process?

You can start smokebot at some future time using `crontab` with an entry like the following:
```
PATH=/bin:/usr/bin:/usr/local/bin:$PATH
MAILTO=""
# .---------------- minute (0 - 59)
# |   .------------- hour (0 - 23)
# |   |   .---------- day of month (1 - 31)
# |   |   |   .------- month (1 - 12) OR jan,feb,mar,apr ...
# |   |   |   |  .----- day of week (0 - 7) (Sunday=0 or 7)  OR sun,mon,tue,wed,thu,fri,sat
# |   |   |   |  |
# *   *   *   *  *  command to be executed
# generate movies at 4:01AM
1 4 * * *    cd $HOME/
Models_central/bot/Smokebot ; bash -lc  "./run_smokebot.sh -J -u -c -U -q smokebot -M -W http://blaze.el.nist.gov/smokebot -w /var/www/html/smokebot > /dev/null"

# run smokebot if FDS or Smokeview source has changed in last 5 minutes
*/5 * * * * cd $HOME/FireModels_central/bot/Smokebot ; bash -lc "./run_smokebot.sh -J -u -c -U -q smokebot -a -W http://blaze.el.nist.gov/smokebot -w /var/www/html/smokebot > /dev/null"
```

The output from smokebot is written into the directory called `output` which is in the same directory as the `smokebot.sh` script itself. When smokebot completes, email should be sent to the specified list of addresses.
