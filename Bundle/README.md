#  Bundling

This directory contains scripts for buildlding FDS and Smokeview bundles.

Preliminary notes on building a bundle.

1. Run firebot on a Linux system to generate FDS publications and FDS and Smokeview applications.
2. Run smokebot on a Linux system to generate Smokeview publications.
3. If you are building a bundle on a Mac, run firebot with the -B option to generate FDS and Smokeview applications.
4. Generate a bundle using make_bundle.sh (located in the `Bundle/fds/scripts` directory).
