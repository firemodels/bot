@echo off

call :rm Git
call :rm Git-r1
call :rm Git-r10
call :rm Git-r11
call :rm Git-r12
call :rm Git-r13
call :rm Git-r14
call :rm Git-r15
call :rm Git-r16
call :rm Git-r17
call :rm Git-r18
call :rm Git-r19
call :rm Git-r2
call :rm Git-r20
call :rm Git-r3
call :rm Git-r4
call :rm Git-r5
call :rm Git-r6
call :rm Git-r7
call :rm Git-r8
call :rm Git-r9
call :rm Git_v0
goto eof

:rm
set tag=%1
git tag -d %tag%
:: git push origin :refs/tags/%tag%
:: git push firemodels :refs/tags/%tag%
exit /b

:eof
