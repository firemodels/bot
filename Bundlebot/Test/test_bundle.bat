@echo off
call fdsinit
call fds_local           test01a.fds
call fds_local -o 4      test01b.fds
call fds_local      -p 4 test04a.fds
call fds_local -o 2 -p 4 test04b.fds
call fds_local -o 2 -p 4 test04c.fds
