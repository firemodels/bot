#!/bin/bash
FDSREVISION=$1
SMVREVISION=$2
DATE="`date`"

cat << EOF
<html>
<head>
<TITLE>Firebot Summary</TITLE>
</HEAD>
<BODY BGCOLOR="#FFFFFF" >
<h2>Firebot Summary - $DATE</h2>
<h3>
FDS build: $FDSREVISION<br>
Smokeview build: $SMVREVISION
</h3>

<h3><a href="diffs.html"</a>Image Comparison</a></h3>
<h3>Guides</h3>
<ul>
<li><a href="manuals/FDS_Config_Management_Plan.pdf">FDS Config Management Plan</a>
<li><a href="manuals/FDS_Technical_Reference_Guide.pdf">FDS Technical Reference Guide</a>
<li><a href="manuals/FDS_User_Guide.pdf">FDS User Guide</a>
<li><a href="manuals/FDS_Validation_Guide.pdf">FDS Validation Guide</a>
<li><a href="manuals/FDS_Verification_Guide.pdf">FDS Verification Guide</a>
</ul>

<p><hr>


</BODY>
</HTML>
EOF
