Webbot is a verification test script that can be run at regular intervals to verify that the links in this project web pages
are not broken. At NIST, this script is run by a pseudo-user webbot on a linux cluster named blaze whenever a
web page changes.  This script may also by run by a normal user after they edit a web page to ensure they have not 
broken any links.

The script is run by the user webbot using the command `webbot.sh -a`
