
#  Building Bundles

### Overview

The directory [bot/Bundlebot/release](https://github.com/firemodels/bot/tree/master/Bundlebot/release) contains scripts for building FDS/Smokeview bundles on Windows, Linux and Macintosh computers. The procedure for bulding bundles is to edit configuration scripts that define tags and associated revisions, to run scripts that build FDS and Smokeview manuals and finally to run scripts that build the bundles.  These steps are given in more detail below: 

   1. Edit `config.sh` and `config.bat` scripts to define revision and tag environmental variables for this bundle.  Commit and push up these changes to the central repo. You may also run the script
      
      `./MakeConfig.sh x.y.z`
      
      to update the configure scripts `config.sh` and `config.bat` where `x.y.z` is the version number of the release.
   3. Type: `sudo su - firebot` on the computer that runs firebot (blaze at Nist) to switch to the firebot user account.
   4. Type: `cd FireModels_bundle/bot/Bundlebot/release` and update the `bot` repo.
   5. Type: `nohup ./BUILD_fds_manuals.sh &` to build the FDS manuals.  After this step completes (about 7 hours) continue to the next step
   6. Type: `nohup ./BUILD_smv_manuals.sh &` to build the Smokeview manuals (in the same account). After this step completes (about 30 minutes) continue to the next step
   7. Type : `nohup ./BUILD_fdssmv_bundle.sh &` on a Linux computer to build a Linux bundle.
   8. Type : `nohup ./BUILD_fdssmv_bundle.sh &` on a Mac computer to build a Mac bundle.
   9. Type: `BUILD_fdssmv_bundle ` on a Windows PC to build a Windows bundle. (nohup is not available on Windows).
   10. Type: `GetBundles.sh` when the bundles are ready to be published to download the bundles to the `bot/Bundlebot/build/bundles` directory .  Type `GetBundles.bat` if on a PC . Draft a new release at https://github.com/firemodels/fds/releases then upload the bundles from the `bundles` directory to this new release.

### Notes
      
1. `nohup` is used when building bundles on Linux and Macintosh computers so that the bundle generating script will continue to run if the command shell is disconnected from your terminal.  The output goes to the file `nohup.out`. Type `tail -f nohup.out` to see  output while the script is running.
2. The scripts for building FDS and Smokeview manuals and building the bundle use environment variables to define repo revisions and tags.  These variables are defined in the scripts `config.sh` (on Linux and Macintosh computers) and `config.bat` (on Windows computers).
3. Bundle scripts erase and clone fresh copies of the fds and smv repos. These scripts should not be run in repos where daily work is performed.   At NIST, Linux Manuals are built in the firebot user account in the directory Firemodels_bundle/bot/Bundlebot/build directory on the host blaze.
4. The `BUILD_bundle.sh` and `BUILD_bundle.bat` scripts upload the test bundles to https://github.com/firemodels/test_bundles/releases/tag/BUNDLE_TEST
5. The scripts `GetBundles.sh` (Linux and Mac) and `GetBundles.bat` (Windows PC) download the bundles to the bundles directory where they can then used to create an official release at https://github.com/firemodels/fds/releases.
6. Tags are only created in the local fds and smv repos, they are not pushed up to GitHub. Tags then do not need to be deleted if errors are discovered that require more commits. Once the bundles are published, these tags may be pushed up to github.


