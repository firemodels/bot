
#  Building Bundles

### Overview

The directory [bot/Bundlebot/release](https://github.com/firemodels/bot/tree/master/Bundlebot/release) contains scripts for building FDS/Smokeview and Smokeview bundles for Windows, Linux and Macintosh computers. These scripts clone fresh copies of the repos used to build the bundles. Do not run them in repos where you do regular work.

The steps for bulding bundles are: 
 
  1. Modify configuration scripts,  `config.sh` and `config.bat`, that define tags and associated revisions for the release,
  2. Run the script `BuildFdsManuals.sh` to build FDS manuals (this runs firebot) and the script `BuildSmvManuals.sh` to build Smokeview manuals (this runs smokebot).
  3. Run the script `BuildRelease.sh` to build FDS/Smokeview bundles, and the script `BuildSmvRelease.sh` to build Smokeview bundles,
  4. Push up tags to the central repo and define a release.
  
These steps are given in more detail below.

### Configure The Bundle Scripts,

   1. cd to bot/Scripts and run the script `./update_repos.sh -m` to update repos .  The option `-m` makes sure each repo is set to the master branch before updating.
   2. For each repo, checkout the desired revision if the latest revision is not the revision you want to use to make the bundle.
   3. cd to bot/Bundlebot/release and run the script `MakeConfig.sh` . This script updates the two configuration scripts `config.sh` and `config.bat` by using
      
      `./MakeConfig.sh x.y.z`
      
where `x.y.z is the version number of the release to be built, for example 6.10.0 . The configuration scripts `config.sh` and `config.bat` contain tags and revision for each repo used to build the bundles.
   
   3. Commit changes to `config.sh` and `config.bat` and push up to the central repo.

### Build Manuals

The manuals are built using the firebot account.

   1. Type: `sudo su - firebot` on the computer that runs firebot (spark at Nist) to switch to the firebot user account.
   2. cd to `FireModels_bundle/bot/Bundlebot/release`
   3. Update the bot repo to ensure that the build manuals scripts use the correct `config.sh` script.
   4. To build the FDS manuals, type: `./BuildFdsManuals.sh -o owner -m email@address` .  After this step completes, about 4 hours, continue to the next step
   5. To build Smokeview manuals, type: `./BuildSmvManuals.sh -o owner -m email@address` . After this step completes, about 20 minutes, start building the bundles.

Note `owner` in `-o owner` is the github owner where the manuals will be placed (-o gforney for now) and `m email@address` is the email address where results will be sent.

### Build Bundles

#### Linux and Macintosh bundles

Linux (spark at NIST) and Macintosh (excess at NIST) bundles are built using the firebot account. 

   1. Switch to the firebot account using `sudo su - firebot` .
   2. cd to the `FireModels_bundle/bot/Bundlebot/release` directory
   3. Update the bot repo.
   4. Type : `./BuildRelease.sh -o owner -m email@address`
   
#### Windows bundles

   1. cd to the `FireModels_bundle\bot\Bundlebot\release` directory
   2. Update the bot repo
   3. Type: `BuildRelease `

### Testing

   1. Type: `GetBundles.sh` when the bundles are ready to be published to download the bundles to the `bot/Bundlebot/build/bundles` directory .  Type `GetBundles.bat` if on a PC .
   2. Examine PDF files to ensure the correct version is displayed on the cover page and perform any other checks needed.
   3. Install bundles on each platform and ensure fds and smokeview apps have the correct version string.
   4. Run a simple test case and view with ssmokeview.
      
### Create a Release
   1. Note, each repo on the Linux computer where the FDS manuals were built has the `REPO-x.y.z` tag defined where `REPO` is the repo name and `x.y.z` is the version number specified with the MakeConfigure.sh script run in an earlier step.
   2. cd to each repo (cad, exp, fds, fig, out, smv) and push up the tags using `git push origin --tags`.
   3. Draft a new release at https://github.com/firemodels/fds/releases then upload the bundles and PDF files from the `bundles` directory to this new release.

### Notes
      
2. The scripts for building FDS and Smokeview manuals and building the bundle use environment variables to define repo revisions and tags.  These variables are defined in the scripts `config.sh` (on Linux and Macintosh computers) and `config.bat` (on Windows computers).
3. Bundle scripts erase and clone fresh copies of the fds and smv repos. These scripts should not be run in repos where daily work is performed.   At NIST, Linux Manuals are built in the firebot user account in the directory Firemodels_bundle/bot/Bundlebot/build directory on the host blaze.
4. The `BuildRelease.sh` and `BuildRelease.bat` scripts upload the test bundles to https://github.com/firemodels/test_bundles/releases/tag/BUNDLE_TEST
5. The scripts `GetBundles.sh` (Linux and Mac) and `GetBundles.bat` (Windows PC) download the bundles to the bundles directory where they can then used to create an official release at https://github.com/firemodels/fds/releases.
6. Tags are only created in the local fds and smv repos, they are not pushed up to GitHub. Tags then do not need to be deleted if errors are discovered that require more commits. Once the bundles are published, these tags may be pushed up to github.


