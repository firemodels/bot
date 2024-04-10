
#  Building Bundles

### Overview

The directory [bot/Bundlebot/release](https://github.com/firemodels/bot/tree/master/Bundlebot/release) contains scripts for building FDS/Smokeview bundles on Windows, Linux and Macintosh computers. The procedure for bulding bundles is to modify configuration scripts that define tags and associated revisions, to run scripts that build FDS and Smokeview manuals, to run scripts that build the bundles and to push up tags to the central repo and define a release.  These steps are given in more detail below.

### Configure

   1. cd to bot/Scripts and run the script `./update_repos.sh -m` to update repos .  The option `-m` makes sure each repo is in the master branch before updating. If the latest revision is not the revision you want to use to make the bundle, checkout the desired revision.
   2. cd to bot/Bundlebot/release and run the script `MakeConfig.sh` to update the configuration scripts `config.sh` and `config.bat` using
      
      `./MakeConfig.sh x.y.z`
      
where `x.y.z is the version number of the release to be built.
   3. Commit changes to `config.sh` and `config.bat` and push up to the central repo.

### Build Manuals

   1. Type: `sudo su - firebot` on the computer that runs firebot (blaze at Nist) to switch to the firebot user account.
   2. Type: `cd FireModels_bundle/bot/Bundlebot/release` and update the `bot` repo ( to ensure that the bundle scripts use the right `config.sh` script.)
   3. Build FDS manuals. Type: `nohup ./BUILD_fds_manuals.sh &` .  After this step completes (about 7 hours) continue to the next step
   4. Build Smokeview manuals. Type: `nohup ./BUILD_smv_manuals.sh &` . After this step completes (about 30 minutes) continue to the next step.

### Build Bundles

   1. Build Linux bundles. Type : `nohup ./BUILD_fdssmv_bundle.sh &` on a Linux computer.
   2. Build Macintosh bundles. Type : `nohup ./BUILD_fdssmv_bundle.sh &` on a Mac computer.
   3. Build Windows bundles. Type: `BUILD_fdssmv_bundle ` on a Windows PC. (nohup is not available on Windows).

### Testing

   1. Type: `GetBundles.sh` when the bundles are ready to be published to download the bundles to the `bot/Bundlebot/build/bundles` directory .  Type `GetBundles.bat` if on a PC .
   2. Examine PDF files to ensure the right version is output on the cover page and perform any other checks needed.
   3. Install bundles on each platform and ensure fds and smokeview apps have the right version string.
   4. Run a simple test case and view with ssmokeview.
      
### Create a Release
   1. Note, each repo on the Linux computer where the FDS manuals were built has the `REPO-x.y.z` tag defined where `REPO` is the repo name and `x.y.z` is the version number specified with the MakeConfigure.sh script run in an earlier step.
   2. cd to each repo (cad, exp, fds, fig, out, smv) and push up the tags using `git push origin --tags`.
   3. Draft a new release at https://github.com/firemodels/fds/releases then upload the bundles and PDF files from the `bundles` directory to this new release.

### Notes
      
1. `nohup` is used when building bundles on Linux and Macintosh computers so that the bundle generating script will continue to run if the command shell is disconnected from your terminal.  The output goes to the file `nohup.out`. Type `tail -f nohup.out` to see  output while the script is running.
2. The scripts for building FDS and Smokeview manuals and building the bundle use environment variables to define repo revisions and tags.  These variables are defined in the scripts `config.sh` (on Linux and Macintosh computers) and `config.bat` (on Windows computers).
3. Bundle scripts erase and clone fresh copies of the fds and smv repos. These scripts should not be run in repos where daily work is performed.   At NIST, Linux Manuals are built in the firebot user account in the directory Firemodels_bundle/bot/Bundlebot/build directory on the host blaze.
4. The `BUILD_bundle.sh` and `BUILD_bundle.bat` scripts upload the test bundles to https://github.com/firemodels/test_bundles/releases/tag/BUNDLE_TEST
5. The scripts `GetBundles.sh` (Linux and Mac) and `GetBundles.bat` (Windows PC) download the bundles to the bundles directory where they can then used to create an official release at https://github.com/firemodels/fds/releases.
6. Tags are only created in the local fds and smv repos, they are not pushed up to GitHub. Tags then do not need to be deleted if errors are discovered that require more commits. Once the bundles are published, these tags may be pushed up to github.


