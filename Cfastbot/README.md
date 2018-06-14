# CFASTbot: A Continuous Integration Tool for CFAST

CFASTbot is a verification test script that can be run at a regular intervals as part of a continuous integration program. At NIST, the script is run by a pseudo-user named `cfast` on a linux cluster each day. The pseudo-user `cfast` updates the various repositories in the GitHub project named `firemodels`, compiles CFAST and Smokeview, runs the validation and verification cases, checks the results for accuracy, and compiles all of the manuals. The entire process takes about an hour to complete.

## Set-Up

The following steps need only be done once. The exact phrasing of the commands are for the NIST linux cluster named blaze. You might need to modify the path and module names.

1. Clone the repositories that are included in the GitHub organization called `firemodels`: `cfast`, `smv`, `bot`, and `exp`. Clone `bot` first, then cd into `bot/Scripts` and type `./setup_repos.sh -c` . This will clone all the other repos needed in the same directory as `bot` (or you can clone each repo in the same way as you cloned `bot`).


2. Ensure that the following software packages are installed on the system:

    * Intel Fortran and C compilers and Intel Inspector
    * Gnu Fortran compiler
    * LaTeX (TeX Live distribution), be sure to make this the default LaTeX in the system-wide PATH
    * Matlab (test the command `matlab`)

3. CFASTbot uses email notifications for build status updates. Ensure that outbound emails can be sent using the `mail` command.

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
    Note that these modules load the Intel Fortran and Gnu Fortran compilers, both of which are used to check CFAST for syntax errors and consisistency with the Fortran 2008 standard.
    
6. Setup passwordless SSH for the your account. Generate SSH keys and ensure that the head node can SSH into all of the compute nodes. Also, make sure that your account information is propagated across all compute nodes.

7. If desired, ensure that a queue named `smokebot` is created, enabled, and started in the torque queueing system and that nodes are defined for this queue. Test the `qstat` command.  If you use some other queue say batch then use `-q batch` when running CFASTbot.  

8. By default, CFASTbot sends email to the email address configured for your bot repo (output of command `git config user.email` ) .  If you wish email to go to different email addresses, create a file named $HOME/.cfastbot/cfastbot_email_list.sh for some `user1` and `user2` (or more) that looks like:
   ```
   #!/bin/bash
   mailToFCFAST="user1@host1.com, user2@host2.com"
   ```

## Running CFASTbot

The script `cfastbot.sh` is run using the wrapper script `run_cfastbot.sh`. This script uses a semaphore file that ensures multiple instances of firebot do not run, which would cause file conflicts. To see the various options associated with running cfastbot, type
```
./run_cfastbot.sh -H
```
Important things to consider: do you want to test your own local changes, or update your repositories from the central repository? Do you want to skip certain stages of the process?

You can start cfastbot at some future time using `crontab` with an entry like the following:
```
PATH=/bin:/usr/bin:/usr/local/bin:/home/<username>/firemodels/bot/Cfastbot:$PATH
MAILTO=""
# Run cfastbot at 9:56 PM every night
56 21 * * * cd ~/<username>/firemodels/bot/Cfastbot ; bash -lc "./run_cfastbot.sh <options>"
```
The output from CFASTbot is written into the directory called `output` which is in the same directory as the `cfastbot.sh` script itself. When cfastbot completes, email should be sent to the specified list of addresses.
