@echo off

cd ..\..\smv\Verification\scripts
if %1 == firebot  call MakeFDSPictures 
if %1 == smokebot call MakeSmvPictures 
