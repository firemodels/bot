Webbot is a verification test script that can be run at regular intervals to verify that the links in this project web pages
are not broken. At NIST, this script is run by a pseudo-user smokebot (not webbot) on a linux cluster named blaze whenever a
web page changes.  This script may also by run by a normal user when they edit a web page so that they know they have not 
broken any links.

The script is run by smokebot using the command `webbot.sh -a`
