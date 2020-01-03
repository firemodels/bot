@echo off
set repo=%1

if NOT "x%repo%" == "x" goto ENDIF1
  echo ***error: specify repo name
  exit /b
:ENDIF1

set GITHEADERfile=githeader.txt
set GITUSERfile=gituser.txt
set ndisablefile=disable.txt
set havecentralfile=havencentral.txt

git remote -v | grep origin | head -1 | gawk  "{print $2}" | gawk -F ":" "{print $1}" > %GITHEADERfile%
set /p GITHEADER=<%GITHEADERfile%

if NOT "%GITHEADER%" == "git@github.com" goto ELSE2
   set GITHEADER=git@github.com:
   git remote -v | grep origin | head -1 | gawk -F ":" "{print $2}" | gawk -F"/" "{print $1}" > %GITUSERfile%
   set /p GITUSER=<%GITUSERfile%
   goto ENDIF2
:ELSE2
   set GITHEADER=https://github.com/
   git remote -v | grep origin | head -1 | gawk -F "." "{print $2}" | gawk -F"/" "{print $2}" > %GITUSERfile%
   set /p GITUSER=<%GITUSERfile%
:ENDIF2

if NOT "%GITUSER%" == "firemodels" goto ELSE3
   git remote -v | grep DISABLE | wc -l > %ndisablefile%
   set /p  ndisable=<%ndisablefile%
   if NOT %ndisable% == 0 goto ELSE6
     echo disabling push access to firemodels
     git remote set-url --push origin DISABLE
     goto ENDIF6
   :ELSE6
     echo push access to firemodels already disabled
   :ENDIF6
   goto ENDIF3
:ELSE3
   
   git remote -v | gawk "{print $1}" | grep firemodels | wc -l > %havecentralfile%
   set /p havecentral=<%havecentralfile%

   if NOT %havecentral% == 0 goto ENDIF4
      echo setting up remote tracking with firemodels
      git remote add firemodels %GITHEADER%firemodels/%repo%.git
      git remote update
   :ENDIF4
   git remote -v | grep DISABLE | wc -l > %ndisablefile%
   set /p  ndisable=<%ndisablefile%
   if NOT %ndisable% == 0 goto ELSE5
     echo disabling push access to firemodels
     git remote set-url --push firemodels DISABLE
     goto ENDIF5
   :ELSE5
     echo push access to firemodels already disabled
   :ENDIF5
:ENDIF3

if EXIST %GITHEADERfile%    erase %GITHEADERfile%
if EXIST %GITUSERfile%      erase %GITUSERfile%
if EXIST %ndisablefile%     erase %ndisablefile%
if EXIST %havecentralfile%  erase %havecentralfile%

echo.
echo remotes for repo %repo%:
git remote -v
