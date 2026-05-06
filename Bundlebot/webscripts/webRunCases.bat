@echo off

cd ..\..\smv\Verification\scripts
if %1 == firebot  call RunFDSCases 
if %1 == smokebot call RunSmvCases 
