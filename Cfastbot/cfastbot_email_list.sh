#!/bin/bash

# cfastbot by default sends emails to the email address set up for the
# bot repo ( git config user.email ) .  If you wish to use a different
# email address use the -m option when running run_cfastbot.sh or copy
# the file cfastbot_email_list.sh to
#    $HOME/.cfastbot/cfastbot_email_list 
# and change the following line to the list of email addresses you wish.

mailTo=""
