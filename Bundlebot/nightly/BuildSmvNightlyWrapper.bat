@echo off
setlocal

set outfile=%userprofile%\.bundle\bundle_smv_nightly.out

call BuildSmvNightly > %outfile% 2>&1
