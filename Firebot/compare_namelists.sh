#!/bin/bash

rm -f output/namelists_f90.txt
rm -f output/namelists_tex.txt
rm -f output/namelists_diff.txt
# generate list of namelist keywords found in FDS_User_Guide tex files
tex_dir=../../fds/Manuals/FDS_User_Guide/
awk -F'}' 'BEGIN{inlongtable=0;}{if($1=="\\begin{longtable"&&$4=="|l|l|l|l|l|"){inlongtable=1};if($1=="\\end{longtable"){inlongtable=0};if(inlongtable==1){print $0}}' $tex_dir/*.tex | \
awk -F' ' 'BEGIN{output=0;namelist="xxx";}{if($1=="\\multicolumn{5}{|c|}{{\\ct"){namelist=$2;};if($1=="{\\ct"){keyword=$2;if(keyword=="\\footnotesize"){keyword=$3;}output=1;}else{output=0;};if(output==1){print "/"namelist"/"keyword;}}' | \
tr -d '}' | \
tr -d '\\' | \
awk -F'(' '{print $1}' | \
tr -d ',' | \
tr -d '&' | \
sort > output/namelists_tex.txt
echo   FDS user guide namelist keywords in output/namelists_tex.txt

# generate list of namelist keywords found in FDS Fortran 90 source  files
input_dir=../../fds/Source
cat $input_dir/*.f90 | \
sed ':a;N;$!ba;s/&\n/ /g' | \
tr -d ' ' | \
grep ^NAMELIST | \
awk -F'/' '{print "/"$2"/,"$3}'  | \
awk -F',' '{for(i=2; i<=NF; i++){print $1$i}}' | \
sort > output/namelists_f90.txt
echo   FDS Fortran 90 namelist keywords in output/namelists_f90.txt

diff output/namelists_f90.txt output/namelists_tex.txt > output/namelists_diff.txt
echo difference in output/namelists_diff.txt
