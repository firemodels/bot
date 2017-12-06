@echo off
set repo=%~f1

set cfastrepo=%repo%\cfast
set fdsrepo=%repo%\fds
set smvrepo=%repo%\smv
set botrepo=%repo%\bot

set clean=%2
set update=%3
set altemail=%4
set emailto=%5

set fdsbranch=master
set smvbranch=master
set cfastbranch=master

::  set number of OpenMP threads

set OMP_NUM_THREADS=1

:: -------------------------------------------------------------
::                         set repository names
:: -------------------------------------------------------------

set abort=0
if NOT exist %smvrepo% (
  echo ***Error: the repository %smvrepo% does not exist
  set abort=1
)

if NOT exist %fdsrepo% (
  echo ***Error: the repository %fdsrepo% does not exist
  set abort=1
)

if NOT exist %cfastrepo% (
  echo ***Error: the repository %cfastrepo% does not exist
  set abort=1
)

if %abort% == 1 (
   echo smokebot aborted
   exit /b
)
:: -------------------------------------------------------------
::                         setup environment
:: -------------------------------------------------------------

set CURDIR=%CD%

if not exist output mkdir output
if not exist history mkdir history
if not exist timings mkdir timings

set OUTDIR=%CURDIR%\output
set HISTORYDIR=%CURDIR%\history
set TIMINGSDIR=%CURDIR%\timings
set timefile=%OUTDIR%\time.txt

erase %OUTDIR%\*.txt 1> Nul 2>&1

set email=%botrepo%\Scripts\email.bat

set emailaltsetup=%userprofile%\bin\setup_gmail.bat
if "%altemail%" == "1" (
  if exist %emailaltsetup% (
     call %emailaltsetup%  
  )
)

set debug=1
set release=0
set errorlog=%OUTDIR%\stage_errors.txt
set warninglog=%OUTDIR%\stage_warnings.txt
set errorwarninglog=%OUTDIR%\stage_errorswarnings.txt
set infofile=%OUTDIR%\stage_info.txt
set revisionfilestring=%OUTDIR%\revision.txt
set revisionfilenum=%OUTDIR%\revision_num.txt
set stagestatus=%OUTDIR%\stage_status.log

set fromsummarydir=%smvrepo%\Manuals\SMV_Summary

set haveerrors=0
set havewarnings=0
set haveCC=1

set emailexe=%userprofile%\bin\mailsend.exe
set gettimeexe=%userprofile%\FIRE-LOCAL\repo_exes\get_time.exe

date /t > %OUTDIR%\starttime.txt
set /p startdate=<%OUTDIR%\starttime.txt
time /t > %OUTDIR%\starttime.txt
set /p starttime=<%OUTDIR%\starttime.txt

call "%smvrepo%\Utilities\Scripts\setup_intel_compilers.bat" 1> Nul 2>&1
call %repo%\bot\Smokebot\firebot_email_list.bat

echo.
echo Settings
echo --------
echo     cfast repo: %cfastrepo%
echo       FDS repo: %fdsrepo%
echo Smokeview repo: %smvrepo%
echo        run dir: %CURDIR%
if NOT "%emailto%" == "" (
  echo          email: %emailto%
  set mailToSMV=%emailto%
)
if %clean% == 1 (
echo    clean repos: yes
) else (
echo    clean repos: no
)
if %update% == 1 (
echo   update repos: yes
) else (
echo   update repos: no
)
echo.

:: -------------------------------------------------------------
::                           stage 0
:: -------------------------------------------------------------

echo Settings
echo --------

:: check if compilers are present

echo. > %errorlog%
echo. > %warninglog%
echo. > %stagestatus%

call :is_file_installed %gettimeexe%|| exit /b 1
echo    found get_time

call :GET_TIME TIME_beg
call :GET_TIME PRELIM_beg

ifort 1> %OUTDIR%\stage0a.txt 2>&1
type %OUTDIR%\stage0a.txt | find /i /c "not recognized" > %OUTDIR%\stage_count0a.txt
set /p nothaveFORTRAN=<%OUTDIR%\stage_count0a.txt
if %nothaveFORTRAN% == 1 (
  echo "***Fatal error: Fortran compiler not present"
  echo "***Fatal error: Fortran compiler not present" > %errorlog%
  echo "smokebot run aborted"
  call :output_abort_message
  exit /b 1
)
echo    found Fortran

icl 1> %OUTDIR%\stage0b.txt 2>&1
type %OUTDIR%\stage0b.txt | find /i /c "not recognized" > %OUTDIR%\stage_count0b.txt
set /p nothaveCC=<%OUTDIR%\stage_count0b.txt
if %nothaveCC% == 1 (
  set haveCC=0
  echo "***Warning: C/C++ compiler not found - using installed Smokeview to generate images"
) else (
  echo    found C/C++
)

if NOT exist %emailexe% (
  echo ***warning: email client not found.   
  echo    Smokebot messages will only be sent to the console.
) else (
  echo    found mailsend
)

call :is_file_installed pdflatex|| exit /b 1
echo    found pdflatex

call :is_file_installed grep|| exit /b 1
echo    found grep

call :is_file_installed gawk|| exit /b 1
echo    found gawk

call :is_file_installed sed|| exit /b 1
echo    found sed

call :is_file_installed wc|| exit /b 1
echo    found wc

call :is_file_installed cut|| exit /b 1
echo    found cut

call :is_file_installed git|| exit /b 1
echo    found git

echo. 1> %OUTDIR%\stage0.txt 2>&1

:: cleaning repos
echo.
echo Status
echo ------
if %clean% == 0 goto skip_clean1
   echo    Cleaning
   echo       cfast
   call :git_clean %cfastrepo% %cfastbranch% || exit /b 1
   echo       fds
   call :git_clean %fdsrepo% %fdsbranch% || exit /b 1
   echo       smokeview
   call :git_clean %smvrepo% %smvbranch% || exit /b 1
:skip_clean1

:: updating  repos

if %update% == 0 goto skip_update1
  echo    Updating
  echo       cfast
  call :cd_repo %cfastrepo% %cfastbranch% || exit /b 1
  git fetch origin %cfastbranch%  1>> %OUTDIR%\stage0.txt 2>&1
  git merge origin/%cfastbranch%  1>> %OUTDIR%\stage0.txt 2>&1

  echo       fds
  call :cd_repo %fdsrepo% %fdsbranch% || exit /b 1
  git fetch origin %fdsbranch% 1>> %OUTDIR%\stage0.txt 2>&1
  git merge origin/%fdsbranch% 1>> %OUTDIR%\stage0.txt 2>&1

  echo       smv
  call :cd_repo %smvrepo% %smvbranch% || exit /b 1
  git fetch origin %smvbranch% 1>> %OUTDIR%\stage0.txt 2>&1
  git merge origin/%smvbranch% 1>> %OUTDIR%\stage0.txt 2>&1
:skip_update1

call :cd_repo %smvrepo% %smvbranch%
git describe --long --dirty > %revisionfilestring%
set /p revisionstring=<%revisionfilestring%

git log --abbrev-commit . | head -1 | gawk "{print $2}" > %revisionfilenum%
set /p revisionnum=<%revisionfilenum%

set errorlogpc=%HISTORYDIR%\errors_%revisionnum%.txt
set warninglogpc=%HISTORYDIR%\warnings_%revisionnum%.txt

set timingslogfile=%TIMINGSDIR%\timings_%revisionnum%.txt

:: build cfast

echo    building cfast
cd %cfastrepo%\Build\CFAST\intel_win_64
erase *.obj *.mod *.exe 1>> %OUTDIR%\stage0.txt 2>&1
call make_cfast bot 1>> %OUTDIR%\stage0.txt 2>&1
call :does_file_exist cfast7_win_64.exe %OUTDIR%\stage0.txt|| exit /b 1

call :GET_DURATION PRELIM %PRELIM_beg%

:: -------------------------------------------------------------
::                           stage 1
:: -------------------------------------------------------------

call :GET_TIME BUILDFDS_beg

echo  Building FDS

echo    debug

cd %fdsrepo%\Build\impi_intel_win_64_db
erase *.obj *.mod *.exe 1> %OUTDIR%\stage1b.txt 2>&1
call make_fds bot 1>> %OUTDIR%\stage1b.txt 2>&1

call :does_file_exist fds_impi_win_64_db.exe %OUTDIR%\stage1b.txt|| exit /b 1
call :find_fds_warnings "warning" %OUTDIR%\stage1b.txt "Stage 1b"

echo    release

cd %fdsrepo%\Build\impi_intel_win_64
erase *.obj *.mod *.exe 1> %OUTDIR%\stage1d.txt 2>&1
call make_fds bot  1>> %OUTDIR%\stage1d.txt 2>&1

call :does_file_exist fds_impi_win_64.exe %OUTDIR%\stage1d.txt|| exit /b 1
call :find_fds_warnings "warning" %OUTDIR%\stage1d.txt "Stage 1d"

call :GET_DURATION BUILDFDS %BUILDFDS_beg%

:: -------------------------------------------------------------
::                           stage 2
:: -------------------------------------------------------------

call :GET_TIME BUILDSMVUTIL_beg

echo  Building Smokeview

echo    libs

cd %smvrepo%\Build\LIBS\intel_win_64
call makelibs_bot 1>> %OUTDIR%\stage2a.txt 2>&1

echo    debug

cd %smvrepo%\Build\smokeview\intel_win_64
erase *.obj *.mod *.exe smokeview_win_64_db.exe 1> %OUTDIR%\stage2a.txt 2>&1
call make_smv_db -r bot 1>> %OUTDIR%\stage2a.txt 2>&1

call :does_file_exist smokeview_win_64_db.exe %OUTDIR%\stage2a.txt|| exit /b 1
call :find_smokeview_warnings "warning" %OUTDIR%\stage2a.txt "Stage 2a"

echo    release

cd %smvrepo%\Build\smokeview\intel_win_64
erase *.obj *.mod smokeview_win_64.exe 1> %OUTDIR%\stage2b.txt 2>&1
call make_smv -r bot 1>> %OUTDIR%\stage2b.txt 2>&1

call :does_file_exist smokeview_win_64.exe %OUTDIR%\stage2b.txt|| exit /b 1
call :find_smokeview_warnings "warning" %OUTDIR%\stage2b.txt "Stage 2b"

:: -------------------------------------------------------------
::                           stage 3
:: -------------------------------------------------------------

echo  Building FDS/Smokeview utilities

echo    fds2ascii
cd %fdsrepo%\Utilities\fds2ascii\intel_win_64
erase *.obj *.mod *.exe 1> %OUTDIR%\stage3c.txt 2>&1
call make_fds2ascii bot 1>> %OUTDIR%\stage3.txt 2>&1
call :does_file_exist fds2ascii_win_64.exe %OUTDIR%\stage3.txt|| exit /b 1

if %haveCC% == 1 (
  echo    background
  cd %smvrepo%\Build\background\intel_win_64
  erase *.obj *.mod *.exe 1>> %OUTDIR%\stage3.txt 2>&1
  call make_background bot 1>> %OUTDIR%\stage3.txt 2>&1
  call :does_file_exist background.exe %OUTDIR%\stage3.txt

  echo    smokediff
  cd %smvrepo%\Build\smokediff\intel_win_64
  erase *.obj *.mod *.exe 1>> %OUTDIR%\stage3.txt 2>&1
  call make_smokediff bot 1>> %OUTDIR%\stage3.txt 2>&1
  call :does_file_exist smokediff_win_64.exe %OUTDIR%\stage3.txt

  echo    smokezip
  cd %smvrepo%\Build\smokezip\intel_win_64
  erase *.obj *.mod *.exe 1>> %OUTDIR%\stage3.txt 2>&1
  call make_smokezip bot 1>> %OUTDIR%\stage3.txt 2>&1
  call :does_file_exist smokezip_win_64.exe %OUTDIR%\stage3.txt|| exit /b 1

  echo    dem2fds
  cd %smvrepo%\Build\dem2fds\intel_win_64
  erase *.obj *.mod *.exe 1>> %OUTDIR%\stage3.txt 2>&1
  call make_dem2fds bot 1>> %OUTDIR%\stage3.txt 2>&1
  call :does_file_exist dem2fds_win_64.exe %OUTDIR%\stage3.txt|| exit /b 1

  echo    wind2fds
  cd %smvrepo%\Build\wind2fds\intel_win_64
  erase *.obj *.mod *.exe 1>> %OUTDIR%\stage3.txt 2>&1
  call make_wind2fds bot 1>> %OUTDIR%\stage3.txt 2>&1
  call :does_file_exist wind2fds_win_64.exe %OUTDIR%\stage3.txt|| exit /b 1
) else (
  call :is_file_installed background|| exit /b 1
  echo    background not built, using installed version
  call :is_file_installed smokediff|| exit /b 1
  echo    smokediff not built, using installed version
  call :is_file_installed smokezip|| exit /b 1
  echo    smokezip not built, using installed version
  call :is_file_installed dem2fds|| exit /b 1
  echo    dem2fds not built, using installed version
  call :is_file_installed wind2fds|| exit /b 1
  echo    wind2fds not built, using installed version
)

call :GET_DURATION PRELIM %PRELIM_beg%

:: -------------------------------------------------------------
::                           stage 4
:: -------------------------------------------------------------

call :GET_TIME RUNVV_beg

echo  Running verification cases
echo    debug mode

:: run the cases

cd %smvrepo%\Verification\scripts
call Run_SMV_Cases -debug -smvwui 1> %OUTDIR%\stage4a.txt 2>&1

:: check the cases

cd %smvrepo%\Verification\scripts
echo. > %OUTDIR%\stage_error.txt
call Check_SMV_cases -smvwui

:: report errors

call :report_errors Stage 4a, "Debug FDS case errors"|| exit /b 1

echo    release mode

:: run the cases

cd %smvrepo%\Verification\scripts
call Run_SMV_Cases -smvwui 1> %OUTDIR%\stage4b.txt 2>&1

:: check the cases

cd %smvrepo%\Verification\scripts
echo. > %OUTDIR%\stage_error.txt
call Check_SMV_cases -smvwui

:: report errors

call :report_errors Stage 4b, "Release FDS case errors"|| exit /b 1

call :GET_DURATION RUNVV %RUNVV_beg%

:: -------------------------------------------------------------
::                           stage 5
:: -------------------------------------------------------------

call :GET_TIME MAKEPICS_beg

echo  Making Smokeview pictures

cd %smvrepo%\Verification\scripts
call Make_SMV_Pictures -smvwui 1> %OUTDIR%\stage5.txt 2>&1

call :find_smokeview_warnings "error" %OUTDIR%\stage5.txt "Stage 5"

call :GET_DURATION MAKEPICS %MAKEPICS_beg%

:: -------------------------------------------------------------
::                           stage 6
:: -------------------------------------------------------------

call :GET_TIME MAKEGUIDES_beg

echo  Building Smokeview guides

echo    Technical Reference
call :build_guide SMV_Technical_Reference_Guide %smvrepo%\Manuals\SMV_Technical_Reference_Guide 1>> %OUTDIR%\stage6.txt 2>&1

echo    Verification
call :build_guide SMV_Verification_Guide %smvrepo%\Manuals\SMV_Verification_Guide 1>> %OUTDIR%\stage6.txt 2>&1

echo    User
call :build_guide SMV_User_Guide %smvrepo%\Manuals\SMV_User_Guide 1>> %OUTDIR%\stage6.txt 2>&1

:: echo    Utilities
:: call :build_guide SMV_Utilities_Guide %smvrepo%\Manuals\SMV_Utilities_Guide 1>> %OUTDIR%\stage6.txt 2>&1

:: echo    Geom Notes
:: call :build_guide geom_notes %smvrepo%\Manuals\FDS_User_Guide 1>> %OUTDIR%\stage6.txt 2>&1

call :GET_DURATION MAKEGUIDES %MAKEGUIDES_beg%
call :GET_DURATION TOTALTIME %TIME_beg%

:: -------------------------------------------------------------
::                           wrap up
:: -------------------------------------------------------------

date /t > %OUTDIR%\stoptime.txt
set /p stopdate=<%OUTDIR%\stoptime.txt
time /t > %OUTDIR%\stoptime.txt
set /p stoptime=<%OUTDIR%\stoptime.txt

echo. > %infofile%
echo . -----------------------------         >> %infofile%
echo .         host: %COMPUTERNAME%          >> %infofile%
echo .        start: %startdate% %starttime% >> %infofile%
echo .         stop: %stopdate% %stoptime%   >> %infofile%
echo .        setup: %DIFF_PRELIM%           >> %infofile%
echo .    run cases: %DIFF_RUNVV%            >> %infofile%
echo .make pictures: %DIFF_MAKEPICS%         >> %infofile%
echo .  make guides: %DIFF_MAKEGUIDES%       >> %infofile%
echo .        total: %DIFF_TOTALTIME%        >> %infofile%
echo . -----------------------------         >> %infofile%

copy %infofile% %timingslogfile%

echo summary   (local): file://%smvrepo%/Manuals/SMV_Summary/index.html >> %infofile%
echo summary (windows): https://googledrive.com/host/0B-W-dkXwdHWNUElBbWpYQTBUejQ/index.html >> %infofile%
echo summary   (linux): https://googledrive.com/host/0B-W-dkXwdHWNN3N2eG92X2taRFk/index.html >> %infofile%
  

cd %CURDIR%

sed "s/$/\r/" < %warninglog% > %warninglogpc%
sed "s/$/\r/" < %errorlog% > %errorlogpc%

if exist %emailexe% (
  if %havewarnings% == 0 (
    if %haveerrors% == 0 (
      call %email% %mailToSMV% "smokebot success on %COMPUTERNAME%! %revisionstring%" %infofile%
    ) else (
      echo "start: %startdate% %starttime% " > %infofile%
      echo " stop: %stopdate% %stoptime% " >> %infofile%
      echo. >> %infofile%
      type %errorlogpc% >> %infofile%
      call %email% %mailToSMV% "smokebot failure on %COMPUTERNAME%! %revisionstring%" %infofile%
    )
  ) else (
    if %haveerrors% == 0 (
      echo "start: %startdate% %starttime% " > %infofile%
      echo " stop: %stopdate% %stoptime% " >> %infofile%
      echo. >> %infofile%
      type %warninglogpc% >> %infofile%
      %email% %mailToSMV% "smokebot success with warnings on %COMPUTERNAME% %revisionstring%" %infofile%
    ) else (
      echo "start: %startdate% %starttime% " > %infofile%
      echo " stop: %stopdate% %stoptime% " >> %infofile%
      echo. >> %infofile%
      type %errorlogpc% >> %infofile%
      echo. >> %infofile%
      type %warninglogpc% >> %infofile%
      call %email% %mailToSMV% "smokebot failure on %COMPUTERNAME%! %revisionstring%" %infofile%
    )
  )
)

echo smokebot_win completed
goto :eof

:output_abort_message
  echo "***Fatal error: smokebot failure on %COMPUTERNAME% %revisionstring%"
  if exist %emailexe% (
    call %email% %mailToSMV% "smokebot failure on %COMPUTERNAME% %revisionstring%" %errorlog%
  )
exit /b

:: -------------------------------------------------------------
:report_errors
:: -------------------------------------------------------------
set stage_label=%1
grep -v " " %OUTDIR%\stage_error.txt | wc -l > %OUTDIR%\stage_nerror.txt
set /p nerrors=<%OUTDIR%\stage_nerror.txt
if %nerrors% GTR 0 (
   echo %stage_label% >> %errorlog%
   echo. >> %errorlog%
   type %OUTDIR%\stage_error.txt >> %errorlog%
   set haveerrors=1
   set haveerrors_now=1
   call :output_abort_message
   exit /b 1
)
exit /b 0

:: -------------------------------------------------------------
:GET_DURATION
:: -------------------------------------------------------------

:: compute difftime=time2 - time1

set label=%1
set time1=%2

set difftime=DIFF_%label%
call :GET_TIME time2

set /a diff=%time2% - %time1%
set /a diff_h= %diff%/3600
set /a diff_m= (%diff% %% 3600 )/60
set /a diff_s= %diff% %% 60
if %diff% GEQ 3600 set duration= %diff_h%h %diff_m%m %diff_s%s
if %diff% LSS 3600 if %diff% GEQ 60 set duration= %diff_m%m %diff_s%s
if %diff% LSS 3600 if %diff% LSS 60 set duration= %diff_s%s
echo %label%: %duration% >> %stagestatus%
set %difftime%=%duration%
exit /b 0

:: -------------------------------------------------------------
:GET_TIME
:: -------------------------------------------------------------

set arg1=%1

%gettimeexe% > %timefile%
set /p %arg1%=<%timefile%
exit /b 0

:: -------------------------------------------------------------
:is_file_installed
:: -------------------------------------------------------------

  set program=%1
  %program% --help 1>> %OUTDIR%\stage_exist.txt 2>&1
  type %OUTDIR%\stage_exist.txt | find /i /c "not recognized" > %OUTDIR%\stage_count.txt
  set /p nothave=<%OUTDIR%\stage_count.txt
  if %nothave% == 1 (
    echo "***Fatal error: %program% not present"
    echo "***Fatal error: %program% not present" > %errorlog%
    echo "smokebot run aborted"
    call :output_abort_message
    exit /b 1
  )
  exit /b 0

:: -------------------------------------------------------------
:chk_repo
:: -------------------------------------------------------------

set repodir=%1

if NOT exist %repodir% (
  echo ***error: repo directory %repodir% does not exist
  echo  smokebot aborted
  exit /b 1
)
exit /b 0

:: -------------------------------------------------------------
:cd_repo
:: -------------------------------------------------------------

set repodir=%1
set repobranch=%2

call :chk_repo %repodir% || exit /b 1

cd %repodir%
if "%repobranch%" == "" (
  exit /b 0
)
git rev-parse --abbrev-ref HEAD>current_branch.txt
set /p current_branch=<current_branch.txt
erase current_branch.txt
if "%repobranch%" NEQ "%current_branch%" (
  echo ***error: found branch %current_branch% was expecting branch %repobranch%
  echo  smokebot aborted
  exit /b 1
)
exit /b 0

:: -------------------------------------------------------------
  :does_file_exist
:: -------------------------------------------------------------

set file=%1
set outputfile=%2

if NOT exist %file% (
  echo ***fatal error: problem building %file%. Aborting smokebot
  type %outputfile% >> %errorlog%
  call :output_abort_message
  exit /b 1
)
exit /b 0

:: -------------------------------------------------------------
  :find_smokeview_warnings
:: -------------------------------------------------------------

set search_string=%1
set search_file=%2
set stage=%3

grep -v "commands for target" %search_file% > %OUTDIR%\stage_warning0.txt
grep -i -A 5 -B 5 %search_string% %OUTDIR%\stage_warning0.txt > %OUTDIR%\stage_warning.txt
type %OUTDIR%\stage_warning.txt | find /v /c "kdkwokwdokwd"> %OUTDIR%\stage_nwarning.txt
set /p nwarnings=<%OUTDIR%\stage_nwarning.txt
if %nwarnings% GTR 0 (
  echo %stage% warnings >> %warninglog%
  echo. >> %warninglog%
  type %OUTDIR%\stage_warning.txt >> %warninglog%
  set havewarnings=1
)
exit /b

:: -------------------------------------------------------------
  :find_fds_warnings
:: -------------------------------------------------------------

set search_string=%1
set search_file=%2
set stage=%3

grep -v "mpif.h" %search_file% > %OUTDIR%\stage_warning0.txt
grep -i -A 5 -B 5 %search_string% %OUTDIR%\stage_warning0.txt  > %OUTDIR%\stage_warning.txt
type %OUTDIR%\stage_warning.txt | find /c ":"> %OUTDIR%\stage_nwarning.txt
set /p nwarnings=<%OUTDIR%\stage_nwarning.txt
if %nwarnings% GTR 0 (
  echo %stage% warnings >> %warninglog%
  echo. >> %warninglog%
  type %OUTDIR%\stage_warning.txt >> %warninglog%
  set havewarnings=1
)
exit /b

:: -------------------------------------------------------------
 :git_clean
:: -------------------------------------------------------------

set gitcleandir=%1
set gitbranch=%2

call :cd_repo %gitcleandir% %gitbranch% || exit /b 1
git clean -dxf 1>> Nul 2>&1
git add . 1>> Nul 2>&1
git reset --hard HEAD 1>> Nul 2>&1
exit /b 0

:: -------------------------------------------------------------
 :build_guide
:: -------------------------------------------------------------

set guide=%1
set guide_dir=%2

set guideout=%OUTDIR%\stage6_%guide%.txt

cd %guide_dir%

pdflatex -interaction nonstopmode %guide% 1> %guideout% 2>&1
bibtex %guide% 1> %guideout% 2>&1
pdflatex -interaction nonstopmode %guide% 1> %guideout% 2>&1
pdflatex -interaction nonstopmode %guide% 1> %guideout% 2>&1
bibtex %guide% 1>> %guideout% 2>&1

type %guideout% | find "Undefined control" > %OUTDIR%\stage_error.txt
type %guideout% | find "! LaTeX Error:" >> %OUTDIR%\stage_error.txt
type %guideout% | find "Fatal error" >> %OUTDIR%\stage_error.txt
type %guideout% | find "Error:" >> %OUTDIR%\stage_error.txt

type %OUTDIR%\stage_error.txt | find /v /c "JDIJWIDJIQ"> %OUTDIR%\stage_nerrors.txt
set /p nerrors=<%OUTDIR%\stage_nerrors.txt
if %nerrors% GTR 0 (
  echo Errors from Stage 6 - Build %guide% >> %errorlog%
  type %OUTDIR%\stage_error.txt >> %errorlog%
  set haveerrors=1
)

type %guideout% | find "undefined" > %OUTDIR%\stage_warning.txt
type %guideout% | find "multiply"  >> %OUTDIR%\stage_warning.txt

type %OUTDIR%\stage_warning.txt | find /c ":"> %OUTDIR%\nwarnings.txt
set /p nwarnings=<%OUTDIR%\nwarnings.txt
if %nwarnings% GTR 0 (
  echo Warnings from Stage 6 - Build %guide% >> %warninglog%
  type %OUTDIR%\stage_warning.txt >> %warninglog%
  set havewarnings=1
)

copy %guide%.pdf %fromsummarydir%\manuals

exit /b

:eof
cd %CURDIR%
