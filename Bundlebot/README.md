
#  Building Bundles

### Overview

The directory [bot/Bundlebot/build](https://github.com/firemodels/bot/tree/master/Bundlebot/build) contains scripts for building FDS/Smokeview bundles on Windows, Linux and OSX computers. Steps for building a bundle are: 

   1. edit `bot/Bundlebot/build/BUILD_config.sh` and `bot/Bundlebot/build/BUILD_config.bat` defining revision and tag environmental variables for this bundle.  Commit and push up changes to the central repo (edits can be made in your own bot repo).
   2. Type: `sudo su - firebot` on the host that runs firebot (blaze at Nist) to switch to the firebot account.
   3. `cd FireModels_bundle/bot/Bundlebot/build`
   4. Update the bot repo. The parameter `option` in the following steps can be test or release. `option` defaults to test if it is not specified. Use test until you are ready to build bundles for a release.
   6. `nohup ./BUILD_fds_manuals.sh option &` after this step completes (about 7 hours) continue to next step
   7. `nohup ./BUILD_smv_manuals.sh option &` after this step completes (about 30 minutes) continue to the next step
   8. `nohup ./BUILD_bundle.sh option &` if building a Linux or OSX bundle or 

      `BUILD_bundle option` if building a Windows bundle (nohup is not available on Windows).
      
Note: `nohup` is used when building bundles on Linux and OSX computers so that the bundle generating script will continue to run if the command shell is disconnected from your terminal.  The output goes to the file `nohup.out`. Type: `tail -f nohup.out` to see script output.

These steps are described in more detail below.

### Setting Revisions and Tags  

The scripts for building FDS and Smokeview manuals and building the bundle use environment variables to define repo revisions and tags.  These variables are defined in the scripts `BUNDLE_config.sh` (Linux and OSX) and `BUNDLE_config.bat` (Windows).  These scripts can be modified in your own bot repo as long changes are committed and pushed to the central repo.
1. `cd bot/Bundlebot/build`
2. Edit `BUNDLE_config.sh` and `BUNDLE_config.bat` and define the environment variables: `BUNDLE_FDS_REVISION`, `BUNDLE_FDS_TAG`, `BUNDLE_SMV_REVISION` and `BUNDLE_SMV_TAG` for the revision and tag you wish to build a bundle for.
3. Commit and push up these changes to the central repo .

The variables below were defined using revisions for a firebot pass on Feb 17, 2024. 
```
export BUNDLE_FDS_REVISION=29bcb71
export BUNDLE_FDS_TAG=FDS-6.9.0tst
export BUNDLE_SMV_REVISION=0f8b692
export BUNDLE_SMV_TAG=SMV-6.9.0tst
```

### Bundling Steps

> [!CAUTION]
> Bundle scripts erase and clone fresh copies of the fds and smv repos. These scripts should not be run in repos where daily work is performed.  At NIST, Linux and OSX bundles are built in the firebot user account in the directory Firemodels_bundle/bot/Bundlebot/build on the Linux host blaze.

1. **Build the FDS manuals.** Run the script `BUILD_fds_manuals.sh` in the firebot account.  This script runs firebot using revisions and tags defined in `BUNDLE_config.sh` and takes about 7 hours to complete.  Note, tags are only created in the local fds and smv repos.  They are not pushed up to GitHub. So a tag does not need to be undone if errors are discovered that require more commits, . New tags may be pushed up to github after the bundles are published. FDS manuals built in this step are uploaded to a github release where the bundle generating scripts can access them.
   1. switch to the firebot account (type: `sudo su - firebot`)
   2. `cd Firemodels_bundle/bot/Bundlebot/build`
   3. Update the bot repo.
   4. `nohup ./BUILD_fds_manuals.sh option`
      where `option` is release or test

2. **Build the smokeview manuals.** Smokeview manuals are built similarly to the FDS manuals. This script runs smokebot using revisions and tags defined in BUNDLE_config.sh.  Smokeview manuals built in this step are uploaded to a github release where the bundle generating scripts can access them.
   1. switch to the firebot account if not already there (type: `sudo su - firebot`) . 
   2. `cd Firemodels_bundle/bot/Bundlebot/build`
   3. Update the bot repo.
   4. `nohup ./BUILD_smv_manuals.sh option`
      where `option` is release or test.

3. **Build the bundle.**  After the FDS and smokeview manuals are built, run the script `BUILD_bundle.sh option`  in the firebot account (type: `sudo su - firebot` to switch accounts).  Note, use the same option (release or test) as was used when building the FDS and smokeview manuals. The bundle generating script uploads the bundle to https://github.com/firemodels/fds/releases when option=release and to https://github.com/firemodels/test_bundles/releases/ when option=test .  To build a Windows bundle run the script `BUILD_bundle.bat opton` on a Windows PC.
   1. switch to the firebot account if not already there (type: `sudo su - firebot`)
   2. `cd Firemodels_bundle/bot/Bundlebot/build`
   3. Update the bot repo.
   4. Type: `./BUILD_bundle.sh option` if building a Linux or OSX release bundle. Type `BUILD_release_bundle option` if building a Windows bundle where as before option can be test or release.
  
