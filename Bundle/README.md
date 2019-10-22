#  Bundling

This directory contains scripts for building FDS and Smokeview bundles on Windows, Linux and OSX (Mac) computer platforms.
Currently, this README documents the process for building bundles for Linux and OSX.

The scripts or bundles used to install FDS and Smokeview consist of applications (FDS, Smokeview and Smokeview utilities), 
documents ( User, Verification/Validation and Technical guides), other files and scripts.
Scripts are used to copy these files to the desired location.  FDS and Smokeview applications are built by running
firebot  with the -B option.  This option causes only the applications to be built
not the usual running and checking of verification cases.  FDS and Smokeview manuals are generated
by running a complete firebot and smokebot. For now, the full bots are only run on a Linux system.  

To generate a bundle on a non-Linux system for example Mac, applications are built on that system and documents are copied
from the Linux system where firebot and smokebot were run.  The process of building a bundle then consists of four steps 1. run firebot to generate FDS manuals, 2. run smokebot to generated smokeview manuals, 3. build applications and finally 4. build the bundle from the parts generated in the first 3 steps.  These steps are detailed below.

### Bundling Steps

1. Run firebot on a Linux system to generate FDS publications. If the firebot run is successful, documents are copied into the .firebot/pubs directory.  In addition, fds applications are copied into .firebot/fds and smokeview applications are copied into .firebot/smv (under the home diredtory where firebot was run).
At NIST this occurs nightly.
2. Run smokebot on a Linux system to generate Smokeview publications. Similarly if the smokebot run is successful, documents are copied into the .smokebot/pubs directory (firebot generates both fds and smokeview applications).
At NIST this occurs whenever the fds and/or smokeview source changes or at least once a day if the source has not changed.
3. Run firebot with the -B option on the system where you are generating  the bundle (OSX or Linux) to generate the applications. 
4. Generate a bundle using the make_bundle.sh script located in the `Bundle/fds/scripts` directory.
