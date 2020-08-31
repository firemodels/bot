@echo off

IF "%SETUP_IFORT_COMPILER_64%"=="1" GOTO envexist

  set SETUP_IFORT_COMPILER_64=1

  set I_MPI_ROOT_SAVE=%I_MPI_ROOT%

  IF DEFINED ICPP_COMPILER14 set ICPP_COMPILER=%ICPP_COMPILER14%
  IF DEFINED ICPP_COMPILER15 set ICPP_COMPILER=%ICPP_COMPILER15%
  IF DEFINED ICPP_COMPILER16 set ICPP_COMPILER=%ICPP_COMPILER16%
  IF DEFINED ICPP_COMPILER17 set ICPP_COMPILER=%ICPP_COMPILER17%
  IF DEFINED ICPP_COMPILER18 set ICPP_COMPILER=%ICPP_COMPILER18%
  IF DEFINED ICPP_COMPILER19 set ICPP_COMPILER=%ICPP_COMPILER19%
  IF DEFINED ICPP_COMPILER20 set ICPP_COMPILER=%ICPP_COMPILER20%
  IF DEFINED ICPP_COMPILER21 set ICPP_COMPILER=%ICPP_COMPILER21%

  IF NOT DEFINED ICPP_COMPILER (
    echo "*** Error: Intel ICPP_COMPILER environment variable not defined."
  )
  IF DEFINED ICPP_COMPILER (
    if exist "%ICPP_COMPILER%\bin\compilervars.bat" (
      echo Setting up C/C++ compiler environment
      call "%ICPP_COMPILER%\bin\compilervars" intel64
    )
    if not exist "%ICPP_COMPILER%\bin\compilervars.bat" (
      echo.
      echo ***warning compiler setup script,
      echo    "%ICPP_COMPILER%\bin\compilervars.bat",
      echo    does not exist
      echo.
    )
  )

  set I_MPI_ROOT=%I_MPI_ROOT_SAVE%
  IF NOT DEFINED I_MPI_ROOT (
    echo "*** Error: Intel MPI environment variable, I_MPI_ROOT, not defined."
    echo "    Intel MPI development environment probably not installed."
    exit /b
  )

  echo Setting up MPI environment
  set I_MPI_RELEASE_ROOT=%I_MPI_ROOT%\intel64\lib
  set   I_MPI_DEBUG_ROOT=%I_MPI_ROOT%\intel64\lib
  IF DEFINED IFORT_COMPILER19 set I_MPI_RELEASE_ROOT=%I_MPI_ROOT%\intel64\lib\release
  IF DEFINED IFORT_COMPILER19 set I_MPI_DEBUG_ROOT=%I_MPI_ROOT%\intel64\lib\debug
  IF DEFINED IFORT_COMPILER20 set I_MPI_RELEASE_ROOT=%I_MPI_ROOT%\intel64\lib\release
  IF DEFINED IFORT_COMPILER20 set I_MPI_DEBUG_ROOT=%I_MPI_ROOT%\intel64\lib\debug
  call "%I_MPI_ROOT%\intel64\bin\mpivars" release

:envexist
