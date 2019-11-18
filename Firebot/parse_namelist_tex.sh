#!/bin/bash
tex_file=$1
awk -F'}' 'BEGIN{inlongtable=0;}{if($1=="\\begin{longtable"&&$4=="|l|l|l|l|l|"){inlongtable=1};if($1=="\\end{longtable"){inlongtable=0};if(inlongtable==1){print $0}}' $tex_file | \
awk -F' ' 'BEGIN{output=0;namelist="xxx";}{if($1=="\\multicolumn{5}{|c|}{{\\ct"){namelist=$2;};if($1=="{\\ct"){keyword=$2;output=1;}else{output=0;};if(output==1){print "/"namelist"/"keyword;}}' | tr -d '}' |  tr -d '\\' | \
awk -F'(' '{print $1}' | tr -d ',' | sort

