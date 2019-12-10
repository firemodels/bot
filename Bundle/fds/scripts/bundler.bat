@echo off

set CURDIR=%CD%

call clone_repos

cd %CURDIR%

call make_apps

cd %CURDIR%

call copy_apps fds

cd %CURDIR%
call copy_apps smv

cd %CURDIR%
call copy_pubs firebot firebot  ~firebot/.firebot/pubs   blaze.el.nist.gov

cd %CURDIR%
call copy_pubs firebot smokebot ~smokebot/.smokebot/pubs blaze.el.nist.gov

cd %CURDIR
call make_bundle



