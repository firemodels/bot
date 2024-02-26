
#  Building Bundles

### Overview

The directory [bot/Bundlebot/build](https://github.com/firemodels/bot/tree/master/Bundlebot/build) contains scripts for building FDS/Smokeview bundles on Windows, Linux and OSX computers. Basically you edit a configuration script defining revisions and tags, run scripts for building FDS and Smokeview manuals and finally run scripts for building the bundles.  Steps for building bundles are given in more detail below: 

   1. edit `BUILD_config.sh` and `BUILD_config.bat` defining revision and tag environmental variables for this bundle.  Commit and push up changes to the central repo.
   2. Type: `sudo su - firebot` on the computer that runs firebot (blaze at Nist) to switch to the firebot user account.
   3. Type: `cd FireModels_bundle/bot/Bundlebot/build` and update the `bot` repo.
   4. Type: `nohup ./BUILD_fds_manuals.sh &` to build FDS manuals.  After this step completes (about 7 hours) continue to the next step
   5. Type: `nohup ./BUILD_smv_manuals.sh &` to build Smokeview manuals (in the same account). After this step completes (about 30 minutes) continue to the next step
   6. Type : `nohup ./BUILD_bundle.sh &` on a Linux computer to build a Linux bundle.
   7. Type : `nohup ./BUILD_bundle.sh &` on a Mac computer to build a Mac bundle.
   8. Type: `BUILD_bundle ` on a Windows PC to build a Windows bundle. (nohup is not available on Windows).
   9. Type: `GH2bundles.sh` to download the bundles to the `bundles` directory when the bundles are ready to be published.  Type `GH2bundles.bat` if on a PC . Draft a new release at https://github.com/firemodels/fds/releases then upload the bundles from the `bundles` directory to this new release.

### Notes
      
1. `nohup` is used when building bundles on Linux and OSX computers so that the bundle generating script will continue to run if the command shell is disconnected from your terminal.  The output goes to the file `nohup.out`. Type `tail -f nohup.out` to see  output while the script is running.
2. The scripts for building FDS and Smokeview manuals and building the bundle use environment variables to define repo revisions and tags.  These variables are defined in the scripts `BUNDLE_config.sh` (on Linux and Mac computer) and `BUNDLE_config.bat` (on Windows computers).
3. Bundle scripts erase and clone fresh copies of the fds and smv repos. These scripts should not be run in repos where daily work is performed.   At NIST, Linux Manuals are built in the firebot user account in the directory Firemodels_bundle/bot/Bundlebot/build directory on the host blaze.
4. The `BUILD_bundle.sh` and `BUILD_bundle.bat` scripts upload the test bundles to https://github.com/firemodels/test_bundles/releases/tag/BUNDLE_TEST
5. The scripts `GH2bundles.sh` (Linux and Mac) and `GHbundles.bat` (Windows PC) download the bundles to the bundles directory where they can then used to create an official release at https://github.com/firemodels/fds/releases.
6. Tags are only created in the local fds and smv repos, they are not pushed up to GitHub. Tags then does not need to be deleted if errors are discovered that require more commits. Once the bundles are published, these tags may be pushed up to github.


