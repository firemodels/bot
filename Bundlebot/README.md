
#  Building Bundles

### Overview

The directory [bot/Bundlebot/build](https://github.com/firemodels/bot/tree/master/Bundlebot/build) contains scripts for building FDS/Smokeview bundles on Windows, Linux and OSX computers. Basically you edit two config scripts then run scripts for building manuals and the bundles.  Steps for building bundles are: 

   1. edit `BUILD_config.sh` and `BUILD_config.bat` defining revision and tag environmental variables for this bundle.  Commit and push up changes to the central rep. These edits can be made in your own bot repo.
   2. Type: `sudo su - firebot` on the computer that runs firebot (blaze at Nist) to switch to the firebot user account.
   3. `cd FireModels_bundle/bot/Bundlebot/build` and update the repo.
   4. Type: `nohup ./BUILD_fds_manuals.sh &` to build FDS manuals.  After this step completes (about 7 hours) continue to the next step
   5. Type: `nohup ./BUILD_smv_manuals.sh &` to build Smokeview manuals (in the same account). After this step completes (about 30 minutes) continue to the next step
   6. Type : `nohup ./BUILD_bundle.sh &` on a Linux computer to build a Linux bundle.

   7. Type : `nohup ./BUILD_bundle.sh &` on a Mac computer to build a Mac bundle.

   8. Type: `BUILD_bundle ` on a Windows PC to build a Windows bundle. (nohup is not available on Windows).

### Notes
      
1. `nohup` is used when building bundles on Linux and OSX computers so that the bundle generating script will continue to run if the command shell is disconnected from your terminal.  The output goes to the file `nohup.out`. Type `tail -f nohup.out` to see  output while the script is running.

2. The scripts for building FDS and Smokeview manuals and building the bundle use environment variables to define repo revisions and tags.  These variables are defined in the scripts `BUNDLE_config.sh` and `BUNDLE_config.bat` .

3. Bundle scripts erase and clone fresh copies of the fds and smv repos. These scripts should not be run in repos where daily work is performed.   At NIST, Linux Manuals are built in the firebot user account in the directory Firemodels_bundle/bot/Bundlebot/build directory on the host blaze.

4. Tags are only created in the local fds and smv repos, they are not pushed up to GitHub. Tags then does not need to be deleted if errors are discovered that require more commits. Once the bundles are published, these tags may be pushed up to github.

5. Bundles are uploaded to https://github.com/firemodels/test_bundles/releases/tag/BUNDLE_TEST when `BUNDLE_OPTION` is set to `test` in the BUILD_config scripts.

6. Bundles are uploaded to https://github.com/firemodels/fds/releases (the official release location) when `BUNDLE_OPTION` is set to `release` in the BUILD_config scripts.
   
