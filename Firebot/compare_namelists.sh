#!/bin/bash
OUTPUT=$1
NAME_PREFIX=$2

if [ "$OUTPUT" == "" ]; then
  OUTPUT=output
fi

if [ "$NAME_PREFIX" != "" ]; then
  NAME_PREFIX=${NAME_PREFIX}_
fi

NAMELIST_F90=$OUTPUT/${NAME_PREFIX}namelists_f90.txt
NAMELIST_TEX=$OUTPUT/${NAME_PREFIX}namelists_tex.txt
NAMELIST_DIFF=$OUTPUT/${NAME_PREFIX}namelists_diff.txt
NAMELIST_NODOC=$OUTPUT/${NAME_PREFIX}namelists_nodoc.txt
NAMELIST_NOSOURCE=$OUTPUT/${NAME_PREFIX}namelists_nosource.txt

#remove files from last comparison
rm -f $OUTPUT/*namelists*txt

# FDS UG directory
tex_dir=../../fds/Manuals/FDS_User_Guide/
# fds source directory
input_dir=../../fds/Source

#ignore namelists found on lines beginning with '% ignorenamelists' in .tex files in the fds/Manuals/FDS_User_Guide directory
IGNORE_NAMELISTS=`grep ignorenamelists: $tex_dir/*.tex | \
	awk -F' ' '\
	{ \
	  if(NF>2){ \
            for(i=3; i<=NF; i++){\
              print "-e /"$i"/ "\
            }\
          }\
        }' | \
       tr -d ','`

#ignore namelist keywords found on lines beginning with '% ignorenamelistkw' in .tex files in the fds/Manuals/FDS_User_Guide directory
IGNORE_NAMELISTKW=`grep ignorenamelistkw: $tex_dir/*.tex | \
	awk -F' ' '\
	{ \
	  if(NF>2){ \
            for(i=3; i<=NF; i++){\
              print "-e "$i" "\
            }\
          }\
        }' | \
       tr -d ','`

#ignore namelist keywords found that occur on any namelist
IGNORE_ALLKW=`grep ignoreallkw: $tex_dir/*.tex | \
	awk -F' ' '\
	{ \
	  if(NF>2){ \
            for(i=3; i<=NF; i++){\
              print "-e /"$i"$ "\
            }\
          }\
        }' | \
       tr -d ','`

IGNORE="$IGNORE_NAMELISTS $IGNORE_NAMELISTKW $IGNORE_ALLKW"

# in case there are no '% ignorenamelists' or '% ignorenamelistkw' lines in the tex files
if [ "$IGNORE" == "" ]; then
  IGNORE="-e /dummy/"
fi

# generate list of namelist keywords found in FDS_User_Guide tex files
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
grep -v $IGNORE |\
sort > $NAMELIST_TEX

# generate list of namelist keywords found in FDS Fortran 90 source  files
cat $input_dir/*.f90 | \
awk -F'!' '{print $1}'  | \
sed ':a;N;$!ba;s/& *\n//g' | \
tr -d ' ' | \
grep ^NAMELIST | \
awk -F'/' '{print "/"$2"/,"$3}'  | \
awk -F',' '{for(i=2; i<=NF; i++){print $1$i}}' | \
grep -v $IGNORE |\
sort > $NAMELIST_F90

#compute difference between tex and f90 namelist/keywords
git diff --no-index $NAMELIST_F90 $NAMELIST_TEX                                  > $NAMELIST_DIFF

nlinesundoc=`grep ^- $NAMELIST_DIFF | sed 's/^-//g' | grep -v Firebot | wc -l`
echo "$nlinesundoc undocumented namelist keywords:"                              > $NAMELIST_NODOC
grep ^- $NAMELIST_DIFF | sed 's/^-//g' | grep -v \\-\\-                         >> $NAMELIST_NODOC

nlinesunimp=`grep ^+ $NAMELIST_DIFF | sed 's/^+//g' | grep -v \\+\\+ | wc -l`
echo "$nlinesunimp unimplemented namelist keywords:"                             > $NAMELIST_NOSOURCE
grep ^+ $NAMELIST_DIFF | sed 's/^+//g' | grep -v \\+\\+                         >> $NAMELIST_NOSOURCE

if [ "$nlinesundoc" == "0" ]; then
  echo "$nlinesundoc undocumented namelist keywords"
else
  echo "$nlinesundoc undocumented namelist keywords: $NAMELIST_NODOC"
fi
if [ "$nlinesunimp" == "0" ]; then
  echo "$nlinesunimp unimplemented namelist keywords"
else
  echo "$nlinesunimp unimplemented namelist keywords: $NAMELIST_NOSOURCE"
fi

