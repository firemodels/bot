#!/bin/bash

# smokebot by default sends emails to the email address set up for the
# bot repo ( git config user.email ) .  If you wish to use a different
# email address use the -m option when running run_smokebot.sh or copy
# this file (smokebot_email_list.sh) to
#    $HOME/.smokebot/smokebot_email_list.sh 
# and change the following line to the list of email addresses you wish.


mailToSMV=""

# email list for fds errors
mailToFDS=""
