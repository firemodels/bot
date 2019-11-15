Webbot is a verification test script that can run at regular intervals to verify that web page links for this project
are not broken. At NIST, this script is run by the pseudo-user webbot on a linux cluster named blaze whenever a
web page changes.  This script may also by run by a normal user after they edit a web page to ensure they have not 
broken any links.

The script is run by the user webbot using the command `run_webbot.sh -a` .  The `-a` option causes the script to proceed
with link checking only if the webpages repo has changed since the last time it was run.  Other options are detailed below

```
Options:
-a - run webbot only if the webpages repo has changed
     since the last time webbot was run
-A - check all web pages in the webpages repo
-c - clean the webpages repo
-f - force webbot to run
-h - display this message
-k - kill webbot if it is running
-u - update the webpages repo
```
