# Firebot Configuration

Firebot is an automatic verification and validation test bot that is run at a regular interval (nightly).
More details on the Firebot build stages can be found in the FDS Configuration Management Plan.

## Set-Up

1. clone firemodels/fds, smv, bot, out, exp repositories

2. Ensure that the following software packages are installed on the system:

    * Intel compilers and Intel Inspector
    * LaTeX (TeX Live distribution), be sure to make this the default LaTeX in the system-wide PATH
    * Matlab (test the command 'matlab')

3. Firebot uses email notifications for build status updates. Ensure that outbound emails can be sent using the 'mail' command.

4. Install libraries for Smokeview. On CentOS, you can use the following command:
   ```
   yum install mesa-libGL-devel mesa-libGLU-devel libXmu-devel libXi-devel xorg-x11-server-Xvfb
   ```

5. Add the following lines to firebot's `~/.bashrc` file:
    ```
    . /usr/local/Modules/3.2.10/init/bash
    module load null modules torque-maui
    module load intel/18

    ulimit -s unlimited
    ```
    
6. Setup passwordless SSH on the firebot account. Generate SSH keys and ensure that the head node can SSH into all of the compute nodes. Also, make sure that firebot's account information is propagated across all compute nodes (e.g., with the passsync or authcopy command).

7. Ensure that a queue named 'firebot' is created, enabled, and started in the torque queueing system and that nodes are defined for this queue. Test the 'qstat' command on firebot's account.

## Running firebot

The script `firebot.sh` is run using the wrapper script `run_firebot.sh`. This script uses a semaphore file that ensures multiple instances of firebot do not run, which would cause file conflicts. This script should be called from `crontab` to start firebot.

The following information is in the Linux firebot user's crontab:
```
PATH=/bin:/usr/bin:/usr/local/bin:/home2/smokevis2/firebot/firebot:$PATH
MAILTO=""

# Update and run Firebot at 9:56 PM every night
# If no SVN argument is specified, then the latest SVN revision is used
56 21 * * * cd ~/firebot ; bash -lc "./run_firebot.sh"
```
