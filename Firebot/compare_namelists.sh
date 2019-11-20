#!/bin/bash

#remove files from last comparison
rm -f output/namelists_f90.txt
rm -f output/namelists_tex.txt
rm -f output/namelists_diff.txt
rm -f output/namelists_nodoc.txt
rm -f output/namelists_nosource.txt

#ignore following namelists
EXIT_PARMS=" -e /CORR/ -e /DOOR/ -e /EDEV/ -e /ENTR/ -e /EVAC/ -e /EVHO/ -e /EVSS/ -e /EXIT/ -e /PERS/ -e /STRS/ " 
DUP_PARMS=" -e /TRNY/ -e /TRNZ/ " 

# generate list of namelist keywords found in FDS_User_Guide tex files
tex_dir=../../fds/Manuals/FDS_User_Guide/
grep -v ^% $tex_dir/*.tex | \
awk -F'}' 'BEGIN{inlongtable=0;}{if($1=="\\begin{longtable"&&$4=="|l|l|l|l|l|"){inlongtable=1};if($1=="\\end{longtable"){inlongtable=0};if(inlongtable==1){print $0}}' $tex_dir/*.tex | \
sed 's/&/ &/g' | \
awk -F' ' 'BEGIN{output=0;namelist="xxx";}\
           {\
             if($1=="\\multicolumn{5}{|c|}{{\\ct"){\
               namelist=$2; \
             }\
             if($1=="{\\ct"){\
               output=1;\
             }\
             else{\
               output=0;\
             };\
             if(output==1){\
               for(i=2; i<=NF; i++){\
                 if($i=="\\footnotesize"){\
                   continue;\
                 };\
		 if($i=="}"){\
	           break;\
		 }\
                 print "/"namelist"/,"$i;\
                 if($i ~ /\}$/){\
                   break;\
                 }\
               }\
             }\
           }'|\
tr -d '}' | \
tr -d '\\' | \
awk -F'(' '{print $1}' | \
tr -d '&' | \
sed 's/,$//g' | \
sed 's/,\//\//g' | \
awk -F',' '{for(i=2; i<=NF; i++){print $1$i}}' | \
grep -v $EXIT_PARMS $DUP_PARMS |\
sort > output/namelists_tex.txt

# generate list of namelist keywords found in FDS Fortran 90 source  files
input_dir=../../fds/Source
cat $input_dir/*.f90 | \
awk -F'!' '{print $1}'  | \
sed ':a;N;$!ba;s/& *\n//g' | \
tr -d ' ' | \
grep ^NAMELIST | \
awk -F'/' '{print "/"$2"/,"$3}'  | \
awk -F',' '{for(i=2; i<=NF; i++){print $1$i}}' | \
grep -v $EXIT_PARMS $DUP_PARMS |\
sort > output/namelists_f90.txt

#compute difference between tex and f90 namelist/keywords
git diff --no-index output/namelists_f90.txt output/namelists_tex.txt > output/namelists_diff.txt

echo "namelist keywords in FDS source not documented in the FDS users guide" > output/namelists_nodoc.txt
grep ^- output/namelists_diff.txt                                           >> output/namelists_nodoc.txt

echo "namelist keywords documented in the FDS users guide but not found in the FDS source" > output/namelists_nosource.txt
grep ^+ output/namelists_diff.txt  >> output/namelists_nosource.txt

echo "    undocumented namelist keywords: output/namelists_nodoc.txt"
echo "   unimplemented namelist keywords: output/namelists_nosource.txt"

