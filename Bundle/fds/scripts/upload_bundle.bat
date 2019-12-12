@echo off
set fds_version_arg=%1
set smv_version_arg=%2
set upload_host=%3

if NOT "x%upload_host%" == "x" goto endif1
  set upload_host=blaze.el.nist.gov
:endif1

set bundle_dir=%userprofile%\.bundle\uploads
set basename=%fds_version_arg%_%smv_version_arg%_win64
set bundlefile=%bundle_dir%\%basename%.exe

if EXIST %bundlefile% goto skip_upload
  echo ***Error: bundle file %basename%.exe does not exist in %upload_dir%
  exit /b 1
:skip_upload

pscp %bundlefile% %upload_host%:.bundle/uploads/.
exit /b 0



