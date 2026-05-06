@echo off
set runallcases=%2

cd ..\..\smv\Verification\scripts
if %1 == firebot  call RunFDSCases  %runallcases%
if %1 == smokebot call RunSmvCases  %runallcases%
