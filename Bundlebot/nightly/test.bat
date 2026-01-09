@echo off
set prog=%1

call :is_file_installed %prog%

goto eof

:: -------------------------------------------------------------
:is_file_installed
:: -------------------------------------------------------------

  set program=%1
  %program% --help 1> %temp%\file_exist.txt 2>&1
  type %temp%\file_exist.txt | find /i /c "not recognized" > %temp%\file_exist_count.txt
  set /p nothave=<%temp%\file_exist_count.txt
  if %nothave% == 1 (
    echo ***Fatal error: %program% not present
    exit /b 1
  )
  exit /b 0

:eof
