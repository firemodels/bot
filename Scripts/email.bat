@echo off
set to=%1
set subject=%2
set file=%3

:: SMTP_xxx variables are predefined environment variables

set mail_setup=1

set SSL=
if "x%SMTP_PORT%" == "x465" (
  set SSL=-ssl
)
if "x%SMTP_USER_NAME%" == "x" set mail_setup=0
if "x%SMTP_SERVER%" == "x" set mail_setup=0
if "x%SMTP_PORT%" == "x" set mail_setup=0
if "x%SMTP_USER_NAME_BASE%" == "x" set mail_setup=0

if %mail_setup% == 0 goto skip_email
mailsend -to %to% -from %SMTP_USER_NAME% -smtp %SMTP_SERVER% %SSL% -port %SMTP_PORT% -sub %subject% -attach %file%,text/plain,i -q -auth-plain -user %SMTP_USER_NAME_BASE%
:skip_email