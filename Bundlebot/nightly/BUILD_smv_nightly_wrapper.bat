@echo off
setlocal

set outfile=%userprofile%\.bundle\bundle_smv_nightly.out

call BUILD_smv_nightly > %outfile% 2>&1