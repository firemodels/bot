@echo off

cd ..\..\smv\Verification\scripts
if %1 == firebot  call CompareFDSPictures 
if %1 == smokebot call CompareSmvPictures 
