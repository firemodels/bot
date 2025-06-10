@echo off
:: cfastbot_win.bat %repo% %usematlab% %clean% %update% %emailto%

set arg1=%1
set repo=%~f1

set cfastrepo=%repo%\cfast
set smvrepo=%repo%\smv
set botrepo=%repo%\bot
set cfastbotdir=%botrepo%\Cfastrepo

set usematlab=%2
set clean=%3
set update=%4
set use_installed_cfast=%5
set use_installed_smokeview=%6
set skip_cases=%7
set official=%8
set emailto=%9

:: pass smokeviewopt and cfastopt variable to the Run_Validation_CFAST.bat script

set smokeviewopt=
if %use_installed_smokeview% == 0 goto skip_smokeviewopt
set smokeviewopt=-smokeview
:skip_smokeviewopt

set cfastopt=
if %use_installed_cfast% == 0 goto skip_cfastopt
set cfastopt=-cfast
:skip_cfastopt

:: -------------------------------------------------------------
::                         set repository names
:: -------------------------------------------------------------

:: check for repos

if NOT exist %cfastrepo% (
  echo ***error: the repo %cfastrepo% does not exist
  echo cfastbot aborted
  exit /b
)

if %use_installed_smokeview% == 0 (
   if NOT exist %smvrepo% (
     echo ***error: the repo %smvrepo% does not exist
     echo cfastbot aborted
     exit /b
   )
)

:: -------------------------------------------------------------
::                         setup environment
:: -------------------------------------------------------------

set CURDIR=%CD%

if not exist output mkdir output
if not exist history mkdir history
if not exist timings mkdir timings

if not exist %userprofile%\.cfast mkdir %userprofile%\.cfast

set PDFS=%userprofile%\.cfast\PDFS
set PDFS_LATEST=%userprofile%\.cfast\PDFS_LATEST

if not exist %PDFS% mkdir %PDFS%
if not exist %PDFS_LATEST% mkdir %PDFS_LATEST%

set OUTDIR=%CURDIR%\output
set HISTORYDIR=%CURDIR%\history
set TIMINGSDIR=%CURDIR%\timings
set timefile=%OUTDIR%\time.txt


erase %OUTDIR%\*.txt 1> Nul 2>&1

set email=%cfastrepo%\Utilities\scripts\email.bat
set emailexe=%userprofile%\bin\mailsend.exe

set errorlog=%OUTDIR%\stage_errors.txt
set warninglog=%OUTDIR%\stage_warnings.txt
set matlabverlog=%OUTDIR%\matlab_ver_log.txt
set matlabvallog=%OUTDIR%\matlab_val_log.txt
set errorwarninglog=%OUTDIR%\stage_errorswarnings.txt
set infofile=%OUTDIR%\summary.txt
set revisionfilestring=%OUTDIR%\revision.txt
set revisionfilenum=%OUTDIR%\revision_num.txt
set stagestatus=%OUTDIR%\stage_status.log
set nothaveValidation=0
set nothaveICC=1

set haveerrors=0
set havewarnings=0

set sh2batexe=sh2bat.exe
set gettimeexe=get_time.exe
set backgroundexe=background.exe
set runbatchexe=runbatch.exe

date /t > %OUTDIR%\starttime.txt
set /p startdate=<%OUTDIR%\starttime.txt
time /t > %OUTDIR%\starttime.txt
set /p starttime=<%OUTDIR%\starttime.txt

call %cfastrepo%\Build\scripts\setup_intel_compilers.bat 1> Nul 2>&1
call %cfastbotdir%\cfastbot_email_list.bat 1> Nul 2>&1

if %usematlab% == 1 (
  echo     matlab: using matlab scripts
)
if %usematlab% == 0 (
  echo matlab: using prebuilt matlab executables
)
if NOT "%emailto%" == "" (
  echo      email: %emailto%
  set mailToCFAST=%emailto%
)
set version=test
if %official% == 1 (
  set version=release
)

echo cfast repo: %cfastrepo%
if %use_installed_smokeview% == 0 (
   echo   SMV repo: %smvrepo%
)
echo.

:: -------------------------------------------------------------
::                           stage 0 - preliminaries
:: -------------------------------------------------------------

echo Stage 0 - Preliminaries

::*** check if various software is installed

echo. > %errorlog%
echo log > %warninglog%
echo. > %stagestatus%

:: ---------------- Fortran

if %use_installed_cfast% == 1 goto skip_ifort
call ..\..\cfast\Build\scripts\setup_intel_compilers.bat
ifx 1> %OUTDIR%\stage0a.txt 2>&1
type %OUTDIR%\stage0a.txt | find /i /c "not recognized" > %OUTDIR%\stage_count0a.txt
set /p nothaveFORTRAN=<%OUTDIR%\stage_count0a.txt
if %nothaveFORTRAN% == 0 (
  echo             found Fortran
) else (
  echo ***error: Fortran compiler not found
  echo           re-run cfastbot using the -cfast or option
  exit /b
)
:skip_ifort

:: ---------------- C/C++

if %use_installed_smokeview% == 1 goto skip_icc
icx 1> %OUTDIR%\stage0a.txt 2>&1
type %OUTDIR%\stage0a.txt | find /i /c "not recognized" > %OUTDIR%\stage_count0a.txt
set /p nothaveICC=<%OUTDIR%\stage_count0a.txt

if %nothaveICC% == 0 (
  echo             found C
) else (
  echo ***error: C compiler not found
  echo           re-run cfastbot using the -smokeview option
  exit /b
)
:skip_icc

set build_utilities=0

:: ---------------- get_time

set build_gettime=0
if %use_installed_smokeview% == 1 goto skip_build_gettime0
if %nothaveICC% == 1 goto skip_build_gettime0
    set build_utilities=1
    set build_gettime=1
    cd %smvrepo%\Build\get_time\intel_win_64
    echo             building get_time
    call make_get_time bot >Nul 2>&1
    set gettimeexe=%smvrepo%\Build\get_time\intel_win_64\get_time_win_64.exe
:skip_build_gettime0
call :is_file_installed %gettimeexe%|| exit /b 1
echo             found get_time

call :GET_TIME TIME_beg
call :GET_TIME PRELIM_beg

:: ---------------- background

set build_background=0
if %use_installed_smokeview% == 1 goto skip_build_background0
if %nothaveICC% == 1 goto skip_build_background0
    set build_background=1
    set build_utilities=1
:skip_build_background0

if %build_background% == 1 goto skip_build_background1
call :is_file_installed %backgroundexe%|| exit /b 1
echo             found background
:skip_build_background1

::---------------- cfast

if %use_installed_cfast% == 0 goto skip_cfast

   set CFDEBUGEXE=cfast
   set CFEXE=cfast
   call :is_file_installed %CFEXE%|| exit /b 1
echo             found cfast

::---------------- VandV_Calcs

set VandVCalcs=VandV_Calcs.exe
   call :is_file_installed %VandVCalcs%|| exit /b 1
echo             found VandVCalcs

:skip_cfast

::---------------- sh2bat

set build_sh2bat=0
if %use_installed_smokeview% == 1 goto skip_sh2bat0
if %nothaveICC% == 1 goto skip_sh2bat0
  set build_utilities=1
  set build_sh2bat=1
:skip_sh2bat0

if %build_sh2bat% == 1 goto skip_sh2bat1
call :is_file_installed %sh2batexe% || exit /b 1
echo             found sh2bat
:skip_sh2bat1

::---------------- smokeview

if %use_installed_smokeview% == 0 goto skip1
if %nothaveICC% == 0 goto skip1
  call :is_smokeview_installed|| exit /b 1
  echo             found smokeview
  set SMOKEVIEW=smokeview.exe
:skip1

::---------------- mailsend

if NOT exist %emailexe% (
  echo ***warning: email client not found. 
  echo             cfastbot messages will only be sent to the console.
) else (
  echo             found mailsend
)

::*** looking for cut

::call :is_file_installed cut|| exit /b 1
::echo             found cut

::*** looking for gawk

call :is_file_installed gawk|| exit /b 1
echo             found gawk

::*** looking for grep

call :is_file_installed grep|| exit /b 1
echo             found grep

::*** looking for head

call :is_file_installed head|| exit /b 1
echo             found head

if %usematlab% == 0 goto skip_matlab

::*** looking for matlab

  where matlab 2>&1 | find /i /c "Could not find" > %OUTDIR%\stage_count0a.txt
  set /p nothavematlab=<%OUTDIR%\stage_count0a.txt
  if %nothavematlab% == 0 (
    echo             found matlab
  )
  if %nothavematlab% == 1 (
    echo             matlab not found - looking for executables
    set usematlab=0
  )
:skip_matlab

::*** looking for pdflatex

call :is_file_installed pdflatex|| exit /b 1
echo             found pdflatex

::*** looking for sed

call :is_file_installed sed|| exit /b 1
echo             found sed

if %usematlab% == 1 goto skip_matlabexe
::*** looking for Validation

  where Validation_Script 2>&1 | find /i /c "Could not find" > %OUTDIR%\stage_count0a.txt
  set /p nothaveValidation=<%OUTDIR%\stage_count0a.txt
  if %nothaveValidation% == 0 (
    echo             found Validation plot generator 
  )
  if %nothaveValidation% == 1 (
    echo             Validation plot generator not found
    echo                Validation guide will not be built 
  )

::*** looking for Verification

  where Verification_Script 2>&1 | find /i /c "Could not find" > %OUTDIR%\stage_count0a.txt
  set /p nothaveVerification=<%OUTDIR%\stage_count0a.txt
  if %nothaveVerification% == 0 (
    echo             found Verification plot generator 
  )
  if %nothaveVerification% == 1 (
    echo             Verification plot generator not found - 
    echo                Validation guide will not be built
    set nothaveValidation=1
  )

:skip_matlabexe

:: --------------------setting up repositories ------------------------------

::*** clean repositories

if %clean% == 0 goto skip_update0
   echo             cleaning repos
   echo               cfast
   call :git_clean %cfastrepo%
   if %use_installed_smokeview% == 1 goto skip_update0
   echo               smv
   call :git_clean %smvrepo%\Build

:skip_update0

::*** update repositories

if %update% == 0 goto skip_update1
  echo             updating repos
  echo               cfast
  cd %cfastrepo%
  git fetch origin
  git merge origin/master  1> %OUTDIR%\stage0.txt 2>&1

  if %use_installed_smokeview% == 1 goto skip_update1
  cd %smvrepo%
  echo               smv
  git fetch origin
  git merge origin/master  1> %OUTDIR%\stage0.txt 2>&1
:skip_update1

cd %cfastrepo%
git log --abbrev-commit . | head -1 | gawk "{print $2}" > %revisionfilestring%
set /p revisionstring=<%revisionfilestring%

git log --abbrev-commit . | head -1 | gawk "{print $2}" > %revisionfilenum%
set /p revisionnum=<%revisionfilenum%

set errorlogpc=%HISTORYDIR%\errors_%revisionnum%.txt
set warninglogpc=%HISTORYDIR%\warnings_%revisionnum%.txt

set timingslogfile=%TIMINGSDIR%\timings_%revisionnum%.txt

git rev-parse --short HEAD > %PDFS_LATEST%\CFAST_HASH

cd %smvrepo%
git rev-parse --short HEAD > %PDFS_LATEST%\SMV_HASH

cd %cfastrepo%

:: -------------------------------------------------------------
::                           stage 1 - build cfast
:: -------------------------------------------------------------

if %use_installed_cfast% == 1 goto skip_build_cfast
echo Stage 1 - Building CFAST and Utilities

echo             debug cfast

cd %cfastrepo%\Build\CFAST\intel_win_64_db
erase *.obj *.mod *.exe *.pdb *.optrpt 1> %OUTDIR%\stage1a.txt 2>&1
call make_cfast bot %version% 1>> %OUTDIR%\stage1a.txt 2>&1


set CFDEBUGEXE=%cfastrepo%\Build\CFAST\intel_win_64_db\cfast7_win_64_db.exe
call :does_file_exist %CFDEBUGEXE% %OUTDIR%\stage1a.txt|| exit /b 1

call :find_cfast_warnings "warning" %OUTDIR%\stage1a.txt "Stage 1a"

echo             debug CData

cd %cfastrepo%\Build\CData\intel_win_64_db
erase *.obj *.mod *.exe *.pdb *.optrpt 1> %OUTDIR%\stage1b.txt 2>&1
call make_cdata bot 1>> %OUTDIR%\stage1b.txt 2>&1

set CData=%cfastrepo%\Build\CData\intel_win_64_db\cdata7_win_64_db.exe
call :does_file_exist cdata7_win_64_db.exe %OUTDIR%\stage1b.txt|| exit /b 1
call :find_cfast_warnings "warning" %OUTDIR%\stage1b.txt "Stage 1b"

echo             release cfast

cd %cfastrepo%\Build\CFAST\intel_win_64
erase *.obj *.mod *.exe *.pdb *.optrpt 1> %OUTDIR%\stage1c.txt 2>&1
call make_cfast bot %version% 1>> %OUTDIR%\stage1c.txt 2>&1

set CFEXE=%cfastrepo%\Build\CFAST\intel_win_64\cfast7_win_64.exe
call :does_file_exist %CFEXE% %OUTDIR%\stage1c.txt|| exit /b 1
call :find_cfast_warnings "warning" %OUTDIR%\stage1c.txt "Stage 1c"

echo             release VandV_Calcs

cd %cfastrepo%\Build\VandV_Calcs\intel_win_64
erase *.obj *.mod *.exe *.pdb *.optrpt 1> %OUTDIR%\stage1d.txt 2>&1
call make_vv bot 1>> %OUTDIR%\stage1d.txt 2>&1

set VandVCalcs=%cfastrepo%\Build\VandV_Calcs\intel_win_64\VandV_Calcs_win_64.exe
call :does_file_exist VandV_Calcs_win_64.exe %OUTDIR%\stage1d.txt|| exit /b 1
call :find_cfast_warnings "warning" %OUTDIR%\stage1d.txt "Stage 1d"

echo             release CData

cd %cfastrepo%\Build\CData\intel_win_64
erase *.obj *.mod *.exe *.pdb *.optrpt 1> %OUTDIR%\stage1e.txt 2>&1
call make_cdata bot 1>> %OUTDIR%\stage1e.txt 2>&1

set CData=%cfastrepo%\Build\CData\intel_win_64\cdata7_win_64.exe
call :does_file_exist cdata7_win_64.exe %OUTDIR%\stage1e.txt|| exit /b 1
call :find_cfast_warnings "warning" %OUTDIR%\stage1e.txt "Stage 1d"

:skip_build_cfast

if %use_installed_cfast% == 0 goto skip_build_cfast1
if %build_utilities% == 0 goto skip_build_cfast1
echo Stage 1b - Building Utilities
:skip_build_cfast1

if %build_gettime% == 0 goto skip_build_gettime
  cd %smvrepo%\Build\get_time\intel_win_64
  echo             get_time
  call make_get_time bot >Nul 2>&1
  set gettimeexe=%smvrepo%\Build\get_time\intel_win_64\get_time_64.exe
  set gettimeex=%smvrepo%\Build\get_time\intel_win_64\get_time_win_64.exe
  if exist %gettimeex% copy %gettimeex% %gettimeexe%
  call :is_file_installed %gettimeexe%|| exit /b 1
:skip_build_gettime

if %build_background% == 0 goto skip_build_background
  cd %smvrepo%\Build\background\intel_win_64
  echo             background
  call make_background bot >Nul 2>&1
  set backgroundexe=%smvrepo%\Build\background\intel_win_64\background.exe
  set backgroundex=%smvrepo%\Build\background\intel_win_64\background_win_64.exe
  if exist %backgroundex% copy %backgroundex% %backgroundexe%
:skip_build_background

if %build_sh2bat% == 0 goto skip_sh2bat
  cd %smvrepo%\Build\sh2bat\intel_win_64
  echo             sh2bat
  call make_sh2bat bot >Nul 2>&1
  set sh2batexe=%smvrepo%\Build\sh2bat\intel_win_64\sh2bat.exe
  set sh2batex=%smvrepo%\Build\sh2bat\intel_win_64\sh2bat_win_64.exe
  if exist %sh2batex% copy %sh2batex% %sh2batexe%
  call :is_file_installed %sh2batexe% || exit /b 1
:skip_sh2bat


:: -------------------------------------------------------------
::                           stage 2 - build smokeview
:: -------------------------------------------------------------

if %use_installed_smokeview% == 1 (
  echo Stage 2 - Skipping Smokeview build
  goto skip_stage2
)
if %nothaveICC% == 1 (
  echo Stage 2 - Skipping Smokeview build - C/C++ not available
  goto skip_stage2
)

echo Stage 2 - Building Smokeview

echo             libs

cd %smvrepo%\Build\LIBS\intel_win_64
call make_LIBS_bot 1>> %OUTDIR%\stage2a.txt 2>&1

echo             debug

cd %smvrepo%\Build\smokeview\intel_win_64
erase *.obj *.mod *.exe smokeview_win_64_db.exe 1> %OUTDIR%\stage2a.txt 2>&1
call make_smokeview_db -release bot 1>> %OUTDIR%\stage2a.txt 2>&1

call :does_file_exist smokeview_win_64_db.exe %OUTDIR%\stage2a.txt|| exit /b 1
call :find_smokeview_warnings "warning" %OUTDIR%\stage2a.txt "Stage 2a"

echo             release

cd %smvrepo%\Build\smokeview\intel_win_64
erase *.obj *.mod smokeview_win_64.exe 1> %OUTDIR%\stage2b.txt 2>&1
call make_smokeview -release bot 1>> %OUTDIR%\stage2b.txt 2>&1
set SMOKEVIEW=%smvrepo%\Build\intel_win_64\smokeview_win_64.exe

call :does_file_exist smokeview_win_64.exe %OUTDIR%\stage2b.txt|| exit /b 1
call :find_smokeview_warnings "warning" %OUTDIR%\stage2b.txt "Stage 2b"
:skip_stage2

if %skip_cases% == 1 goto skip_cases

call :GET_DURATION PRELIM %PRELIM_beg%

:: -------------------------------------------------------------
::                           stage 3 - run cases
:: -------------------------------------------------------------

call :GET_TIME RUNVV_beg

echo Stage 3 - Running validation cases

if %use_installed_cfast% == 1 goto skip_run_debug
echo             debug

cd %cfastrepo%\Validation\scripts

call Run_CFAST_cases -debug %cfastopt% %smokeviewopt% 1> %OUTDIR%\stage3a.txt 2>&1

call :find_runcases_warnings "***Warning"                                  %cfastrepo%\Validation    "Stage 3a-Validation"
call :find_runcases_errors   "error|forrtl: severe|DASSL|floating invalid" %cfastrepo%\Validation    "Stage 3a-Validation"

call :find_runcases_warnings "***Warning"                                  %cfastrepo%\Verification "Stage 3a-Verification"
call :find_runcases_errors   "error|forrtl: severe|DASSL|floating invalid" %cfastrepo%\Verification "Stage 3a-Verification"

:: note: once we verify the that the -check option is working below we can incorporate the above checks into the -check option
cd %cfastrepo%\Validation\scripts
call Run_CFAST_cases -check %cfastopt% %smokeviewopt% 1> %OUTDIR%\stage3aa.txt 2>&1
call :check_cfast_cases %OUTDIR%\stage3aa.txt stage3a

if %clean% == 1 (
   echo             removing debug output files
   call :git_clean %cfastrepo%\Validation
   call :git_clean %cfastrepo%\Verification
)

:skip_run_debug

echo             release

cd %cfastrepo%\Validation\scripts
call Run_CFAST_cases %cfastopt% %smokeviewopt% 1> %OUTDIR%\stage3b.txt 2>&1

call :find_runcases_warnings "***Warning"                                  %cfastrepo%\Validation   "Stage 3b-Validation"
call :find_runcases_errors   "error|forrtl: severe|DASSL|floating invalid" %cfastrepo%\Validation   "Stage 3b-Validation"

call :find_runcases_warnings "***Warning"                                  %cfastrepo%\Verification "Stage 3b-Verification"
call :find_runcases_errors   "error|forrtl: severe|DASSL|floating invalid" %cfastrepo%\Verification "Stage 3b-Verification"

cd %cfastrepo%\Validation\scripts
call Run_CFAST_cases -check %cfastopt% %smokeviewopt% 1> %OUTDIR%\stage3bb.txt 2>&1
call :check_cfast_cases %OUTDIR%\stage3bb.txt stage3b

call :GET_DURATION RUNVV %RUNVV_beg%

:: -------------------------------------------------------------
::                           stage 4 - make pictures
:: -------------------------------------------------------------

:skip_cases
call :GET_TIME MAKEPICS_beg

echo Stage 4 - Making smokeview images

cd %cfastrepo%\Validation\scripts

sh2bat CFAST_Pictures.sh CFAST_Pictures.bat > %OUTDIR%\stage4.txt 2>&1
set RUNSMV=call %cfastrepo%\Validation\scripts\runsmv.bat

cd %cfastrepo%\Validation
set BASEDIR=%CD%

call scripts\CFAST_Pictures.bat 1> %OUTDIR%\stage4.txt 2>&1

:: -------------------------------------------------------------
::                           stage 5 - make validation plots
:: -------------------------------------------------------------

if %nothaveValidation% == 1 goto skip_stage5

echo Stage 5 - Making matlab plots
::*** generating Validation plots

echo             Validation
echo               VandV_Calcs
cd %cfastrepo%\Validation
%VandVCalcs% CFAST_Pressure_Correction_Inputs.csv 1> Nul 2>&1
copy pressures.csv LLNL_Enclosure\LLNL_pressures.csv /Y 1> Nul 2>&1
%VandVCalcs% CFAST_Temperature_Profile_inputs.csv 1> Nul 2>&1
copy profiles.csv Steckler_Compartment /Y 1> Nul 2>&1
%VandVCalcs% CFAST_Heat_Flux_Profile_inputs.csv 1> Nul 2>&1
copy flux_profiles.csv Fleury_Heat_Flux /Y 1> Nul 2>&1



echo               Making plots
cd %cfastrepo%\Utilities\Matlab

if %usematlab% == 0 goto matlab_else1
  matlab -logfile %matlabvallog% -automation -wait -noFigureWindows -r "try; run('%cfastrepo%\Utilities\Matlab\CFAST_validation_script.m'); catch; end; quit
  goto matlab_end1
:matlab_else1
  Validation_Script
  call :WAIT_RUN Validation_Script
:matlab_end1

::*** generating Verification plots

echo             Verification
echo               Making plots
cd %cfastrepo%\Utilities\Matlab
if %usematlab% == 0 goto matlab_else2
  matlab -logfile %matlabverlog% -automation -wait -noFigureWindows -r "try; run('%cfastrepo%\Utilities\Matlab\CFAST_verification_script.m'); catch; end; quit
  goto matlab_end2
:matlab_else2
  Verification_Script
  call :WAIT_RUN Verification_Script
:matlab_end2

:skip_stage5

call :GET_DURATION MAKEPICS %MAKEPICS_beg%

:: -------------------------------------------------------------
::                           stage 6 - make manuals
:: -------------------------------------------------------------

call :GET_TIME MAKEGUIDES_beg

echo Stage 6 - Building CFAST guides

echo             Users Guide
call :build_guide CFAST_Users_Guide %cfastrepo%\Manuals\CFAST_Users_Guide 1>> %OUTDIR%\stage6.txt 2>&1

echo             Technical Reference Guide
call :build_guide CFAST_Tech_Ref %cfastrepo%\Manuals\CFAST_Tech_Ref 1>> %OUTDIR%\stage6.txt 2>&1

if %nothaveValidation% == 0 (
  echo             Validation Guide
  call :build_guide CFAST_Validation_Guide %cfastrepo%\Manuals\CFAST_Validation_Guide 1>> %OUTDIR%\stage6.txt 2>&1
)

echo             Configuration Management Guide
call :build_guide CFAST_Configuration_Guide %cfastrepo%\Manuals\CFAST_Configuration_Guide 1>> %OUTDIR%\stage6.txt 2>&1

echo             CData Guide
call :build_guide CFAST_CData_Guide %cfastrepo%\Manuals\CFAST_CData_Guide 1>> %OUTDIR%\stage6.txt 2>&1

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
echo .------------------------------         >> %infofile%
echo .         host: %COMPUTERNAME%          >> %infofile%
echo .        start: %startdate% %starttime% >> %infofile%
echo .         stop: %stopdate% %stoptime%   >> %infofile%
echo .        setup: %DIFF_PRELIM%           >> %infofile%
echo .    run cases: %DIFF_RUNVV%            >> %infofile%
echo .make pictures: %DIFF_MAKEPICS%         >> %infofile%
echo .  make guides: %DIFF_MAKEGUIDES%       >> %infofile%
echo .        total: %DIFF_TOTALTIME%        >> %infofile%
echo .------------------------------         >> %infofile%

copy %infofile% %timingslogfile%

:: email results

sed "s/$/\r/" < %warninglog% > %warninglogpc%
sed "s/$/\r/" < %errorlog% > %errorlogpc%

if %havewarnings% == 0 (
  if %haveerrors% == 0 (
    set message=success
    erase %PDFS%\*.pdf               1> Nul 2>&1
    copy %PDFS_LATEST%\*.pdf %PDFS%  1> Nul 2>&1

    erase %PDFS%\*HASH               1> Nul 2>&1
    copy %PDFS_LATEST%\*HASH %PDFS%  1> Nul 2>&1
    
  ) else (
    echo. >> %infofile%
    type %errorlogpc% >> %infofile%
    set message=failure
  )
) else (
  if %haveerrors% == 0 (
    echo. >> %infofile%
    type %warninglogpc% >> %infofile%
    set message=success with warnings
  ) else (
    echo. >> %infofile%
    type %errorlogpc% >> %infofile%
    echo. >> %infofile%
    type %warninglogpc% >> %infofile%
    set message=failure
  )
)

if exist %emailexe% (
  call %email% %mailToCFAST% "cfastbot %message% on %COMPUTERNAME%! %revisionstring%" %infofile%
)

echo cfastbot %message% on %COMPUTERNAME%! %revisionstring%, runtime: %DIFF_TOTALTIME%
echo Results summarized in:
echo    %infofile%
cd %CURDIR%
goto eof

::------------ cfastbot "subroutines below ----------------------

:: -------------------------------------------------------------
:output_abort_message
:: -------------------------------------------------------------
  echo "***Fatal error: cfastbot build failure on %COMPUTERNAME% %revision%"
exit /b

:: -------------------------------------------------------------
:WAIT_RUN
:: -------------------------------------------------------------

set prog=%1
:loop5
tasklist | grep -ic %prog% > temp.out
set /p numexe=<temp.out
if %numexe% == 0 goto finished5
Timeout /t 30 >nul 
goto loop5

:finished5
exit /b

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
    echo "cfastbot run aborted"
    call :output_abort_message
    exit /b 1
  )
  exit /b 0

:: -------------------------------------------------------------
:is_smokeview_installed
:: -------------------------------------------------------------

  smokeview -version 1>> %OUTDIR%\stage_exist.txt 2>&1
  type %OUTDIR%\stage_exist.txt | find /i /c "not recognized" > %OUTDIR%\stage_count.txt
  set /p nothave=<%OUTDIR%\stage_count.txt
  if %nothave% == 1 (
    echo "***Fatal error: %program% not present"
    echo "***Fatal error: %program% not present" > %errorlog%
    echo "cfastbot run aborted"
    call :output_abort_message
    exit /b 1
  )
  exit /b 0

:: -------------------------------------------------------------
  :does_file_exist
:: -------------------------------------------------------------

set file=%1
set outputfile=%2

if NOT exist %file% (
  echo ***fatal error: problem building %file%. Aborting cfastbot
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
  :find_runcases_warnings
:: -------------------------------------------------------------

set search_string=%1
set search_dir=%2
set stage=%3

cd %search_dir%
grep -RIiE %search_string% --include *.log --include *.out --include *.err * > %OUTDIR%\stage_warning.txt
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
  :find_runcases_errors
:: -------------------------------------------------------------

set search_string=%1
set search_dir=%2
set stage=%3

cd %search_dir%
grep -RIiE %search_string% --include *.log --include *.out --include *.err * > %OUTDIR%\stage_error.txt
type %OUTDIR%\stage_error.txt | find /v /c "kdkwokwdokwd"> %OUTDIR%\stage_nerror.txt
set /p nerrors=<%OUTDIR%\stage_nerror.txt
if %nerrors% GTR 0 (
  echo %stage% errors >> %errorlog%
  echo. >> %errorlog%
  type %OUTDIR%\stage_error.txt >> %errorlog%
  set haveerrors=1
)
exit /b

:: -------------------------------------------------------------
  :check_cfast_cases
:: -------------------------------------------------------------

set file=%1
set stage=%2

grep -RIiE Error %file% > %OUTDIR%\stage_error2.txt
type %OUTDIR%\stage_error2.txt | find /v /c "kdkwokwdokwd"> %OUTDIR%\stage_nerror2.txt
set /p nerrors=<%OUTDIR%\stage_nerror2.txt
if %nerrors% GTR 0 (
  echo %stage% errors >> %errorlog%
  echo. >> %errorlog%
  type %OUTDIR%\stage_error2.txt >> %errorlog%
  set haveerrors=1
)
exit /b

:: -------------------------------------------------------------
  :find_cfast_warnings
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
cd %gitcleandir%
git clean -dxf  1> Nul 2>&1
git add . 1> Nul 2>&1
git reset --hard HEAD 1> Nul 2>&1
exit /b

:: -------------------------------------------------------------
 :build_guide
:: -------------------------------------------------------------

set guide=%1
set guide_dir=%2

set guideout=%OUTDIR%\stage6_%guide%.txt

cd %guide_dir%

git describe --abbrev=7 --long --dirty > gitinfo.txt
set /p gitrevision=<gitinfo.txt
echo \newcommand^{\gitrevision^}^{%gitrevision%^} > ..\Bibliography\gitrevision.tex

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
if exist %PDFS_LATEST%\%guide%.pdf erase %PDFS_LATEST%\%guide%.pdf 1> Nul 2>&1
copy %guide%.pdf %PDFS_LATEST%\%guide%.pdf 1> Nul 2>&1
exit /b

:eof
