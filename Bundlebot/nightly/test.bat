@echo off
set prog=%1

call :IS_FILE_INSTALLED clamscan
if %ERRORLEVEL% == 1 goto elsescan
echo doing a scan
goto :endifscan
:elsescan
echo not doing a scan
:endifscan


goto eof

:: -------------------------------------------------------------
:IS_FILE_INSTALLED
:: -------------------------------------------------------------

  set program=%1
  %program% --help 1> %temp%\file_exist.txt 2>&1
  type %temp%\file_exist.txt | find /i /c "not recognized" > %temp%\file_exist_count.txt
  set /p nothave=<%temp%\file_exist_count.txt
  if %nothave% == 1 (
    echo ***Error: %program% not installed or not in path
    exit /b 1
  )
  exit /b 0
:eof
