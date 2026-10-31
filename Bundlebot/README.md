
#  Building Bundles

### Overview

The directory [bot/Bundlebot/release](https://github.com/firemodels/bot/tree/master/Bundlebot/release) contains scripts for building FDS/Smokeview and Smokeview bundles for Windows, Linux and Macintosh computers. These scripts clone fresh copies of the repos used to build the bundles. Do not run them in repos where you do regular work.

The steps for bulding bundles are: 
 
  1. Modify tags and revisions in the configuration scripts,  `config.sh` and `config.bat`,
  2. Run the script `BuildFdsManuals.sh` to build FDS manuals (this runs firebot) and the script `BuildSmvManuals.sh` to build Smokeview manuals (this runs smokebot).
  3. Run the script `BuildRelease.sh` to build FDS/Smokeview bundles, and the script `BuildSmvRelease.sh` to build Smokeview bundles,
  4. After the bundles are verified to be correct, push up tags to the central repo and define a release.
  
These steps are given in more detail below.

### Configure The Bundle Scripts,

   1. cd to bot/Scripts and run the script `./update_repos.sh -m` to update the repos .  The option `-m` makes sure each repo is set to the master branch before updating.
   2. For each repo, checkout the desired revision if the latest revision is not the revision you want to use to make the bundle.
   3. cd to bot/Bundlebot/release and run the script `MakeConfig.sh` . This script updates the two configuration scripts `config.sh` and `config.bat` by using
      
      `./MakeConfig.sh x.y.z`
      
where `x.y.z is the version number of the release to be built, for example 6.10.0 . The configuration scripts `config.sh` and `config.bat` contain tags and revision for each repo used to build the bundles.
   
   3. Examine `config.sh` and `config.bat` to ensure they contain revisions and tags that you want then commit changes and push up to the central repo.

### Build Manuals

The manuals are built using the firebot account.

   1. Type: `sudo su - firebot` on the computer that runs firebot (spark at Nist) to switch to the firebot user account.
   2. cd to `FireModels_bundle/bot/Bundlebot/release`
   3. Update the bot repo to ensure that the build manuals scripts use the correct `config.sh` script.
   4. To build the FDS manuals, type: `./BuildFdsManuals.sh -o owner -m email@address` .  After this step completes, about 3 hours, continue to the next step
   5. To build Smokeview manuals, type: `./BuildSmvManuals.sh -o owner -m email@address` . After this step completes, about 20 minutes, start building the bundles.

Note `owner` in `-o owner` is the github owner where the manuals will be placed (-o gforney for now) and `-m email@address` is the email address where results will be sent.

### Build Bundles

#### Local macOS release DMG

Run `bash Bundlebot/release/BuildMacRelease.sh --check` from the bot repository to check the configured FDS and Smokeview commits and download their manuals from GitHub. After this succeeds, run the same command without `--check` to compile and create a DMG. On macOS, `BuildRelease.sh` forwards to this command with the same options. This path uses GNU Fortran and Open MPI on the Mac's native architecture. It requires Git, GitHub CLI authentication, Python 3 with `dmgbuild` and Pillow, CMake, pkg-config, GNU Fortran, Open MPI, and the Xcode command-line tools.

The configuration is `Bundlebot/release/config.sh`. The configured commits must be available in the sibling `fds` and `smv` repositories; those checkouts need not be on the release branch. After the manual checks pass, a build deletes untracked and ignored files in those repositories, discards tracked edits, resets their `release` branches to the configured commits, and updates their local release tags. Treat the sibling repositories as disposable bundle work areas. The existing `bot` checkout and configuration are retained. HYPRE and SUNDIALS use sibling repositories too: existing repositories are fetched, missing ones are cloned, and the FDS build scripts clean and rebuild them at the required library versions. Update the configuration from the release machine before starting. `--check` downloads and checks manuals without resetting source repositories.

Manuals come from `firemodels/test_bundles`, using `FDS_TEST` and `SMOKEVIEW_TEST`. Both Firebot and Smokebot must have finished uploading manuals for the configured commits and version labels. The script checks the uploaded `FDS_INFO.txt` (or the older `FDS_INFO$.txt`) and `SMV_INFO.txt` before compiling; missing manuals or mismatched revisions stop the build. Use `--manuals-repo`, `--fds-manuals-tag`, and `--smv-manuals-tag` to select other releases with the same PDF and metadata assets.

To test packaging with the manuals currently uploaded, add `--allow-manual-revision-mismatch`, optionally alongside `--check`. This bypasses manual hash and version matching for both FDS and Smokeview; all PDFs and metadata assets must still download successfully. Executables still use the commits in `config.sh`. The resulting DMG has a `_manuals_test` suffix and includes a note that manual revisions were not required to match. Omit this option for the release build.

The result is `~/.bundle/bundles/FDS-x.y.z_SMV-x.y.z_macos_arm64.dmg` (or `x86_64`). Use `--output-dir` to change the destination. Like the CFAST DMG, it contains an `FDS6` folder, an Applications shortcut, a README, and a Terminal install menu. Drag `FDS6` onto Applications, then run `source "/Applications/FDS6/bin/FDSVARS.sh"` to add FDS, Smokeview, and MPI to the terminal environment. The folder can also be copied to another location; use that location in the source command. The menu offers Applications, Downloads, and a custom location. The bundle includes FDS, Smokeview, their utilities, Open MPI, runtime libraries, manuals, and verification inputs. GNU builds contain the MPI executable, without the separate Intel OpenMP executable.

To test DMG packaging again after a build, run `bash Bundlebot/release/BuildMacRelease.sh --package-only`. This uses the saved configuration and staged files under `.macos-build`, including the manual-mismatch setting from that build. It does not update repositories, rebuild executables, or download manuals. Eject the previously opened DMG before replacing it. A staged bundle must already exist; `--check` or a new full build replaces that staging directory.

This command produces a local test bundle and never uploads it. Runtime binaries receive ad-hoc signatures after library relocation; the DMG is not Developer ID signed or notarized. Public distribution through Gatekeeper needs a subsequent signing/notarization step. Build logs, downloaded manuals, and intermediate files use a single `.macos-build` directory under the output directory, replaced on each run. A lock prevents simultaneous runs from sharing that staging directory. Completed versioned DMGs remain in the output directory.

#### Linux bundles

Linux (spark at NIST) bundles are built using the firebot account.

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
      
1. The scripts for building FDS and Smokeview manuals and building the bundle use environment variables to define repo revisions and tags.  These variables are defined in the scripts `config.sh` (on Linux and Macintosh computers) and `config.bat` (on Windows computers).
2. Bundle scripts erase and clone fresh copies of the fds and smv repos. These scripts should not be run in repos where daily work is performed.   At NIST, Linux Manuals are built in the firebot user account in the directory Firemodels_bundle/bot/Bundlebot/build directory on the host blaze.
3. The `BuildRelease.sh` and `BuildRelease.bat` scripts upload the test bundles to https://github.com/firemodels/test_bundles/releases/tag/BUNDLE_TEST
4. The scripts `GetBundles.sh` (Linux and Mac) and `GetBundles.bat` (Windows PC) download the bundles to the bundles directory where they can then used to create an official release at https://github.com/firemodels/fds/releases.
5. Tags are only created in the local fds and smv repos, they are not pushed up to GitHub. Tags then do not need to be deleted if errors are discovered that require more commits. Once the bundles are published, these tags may be pushed up to github.
