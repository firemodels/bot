#!/bin/bash

if [ $# -lt 1 ]
then
  echo "Usage: make_installer.sh -i FDS_TAR.tar.gz -d installdir INSTALLER.sh"
  echo ""
  echo "Creates an FDS/Smokeview installer sh script. "
  echo ""
  echo "  -i FDS.tar.gz - compressed tar file containing FDS distribution"
  echo "  -b custombase - custom directory base"
  echo "  -d installdir - default install directory"
  echo "   INSTALLER.sh - bash shell script containing self-extracting Installer"
  echo
  exit
fi

FDSEDITION=FDS6
FDSMODULE=$FDSEDITION
SMVEDITION=SMV6
SMVMODULE=$SMVEDITION
CUSTOMBASE=

FDSVARS=${FDSEDITION}VARS.sh
SMVVARS=${SMVEDITION}VARS.sh

INSTALLDIR=
FDS_TAR=
INSTALLER=
ostype="LINUX"
ostype2="Linux"
if [ "`uname`" == "Darwin" ] ; then
  ostype="OSX"
  ostype2="OSX"
fi

FDS_VERSION=FDS
SMV_VERSION=Smokeview
while getopts 'b:d:f:i:s:' OPTION
do
case $OPTION in
  b)
  CUSTOMBASE="$OPTARG"
  ;;
  d)
  INSTALLDIR="$OPTARG"
# get rid of trailing slashes
  INSTALLDIR=${INSTALLDIR%/}
  ;;
  f)
  FDS_VERSION="$OPTARG"
  ;;
  i)
  FDS_TAR="$OPTARG"
  ;;
  s)
  SMV_VERSION="$OPTARG"
  ;;
esac
done 
shift $(($OPTIND-1))

INSTALLER=$1

if [ "$FDS_TAR" == "" ]
then
echo "*** fatal error: FDS distribution file not specified"
exit 0
fi

if [ "$INSTALLDIR" == "" ]
then
echo "*** fatal error: default install directory not specified"
exit 0
fi

if [ "$INSTALLER" == "" ]
then
echo "*** fatal error: installer not specified"
exit 0
fi

BASHRC2=.bashrc
PLATFORM=linux
LDLIBPATH=LD_LIBRARY_PATH
if [ "$ostype" == "OSX" ]; then
  LDLIBPATH=DYLD_LIBRARY_PATH
  BASHRC2=.bash_profile
  PLATFORM=osx
fi

cat << EOF > $INSTALLER
#!/bin/bash

OVERRIDE=\$1
INSTALL_LOG=/tmp/fds_install_\$\$.log
echo "" > \$INSTALL_LOG
echo ""
echo "Installing $FDS_VERSION and $SMV_VERSION on $ostype2"
echo ""
echo "Options:"
echo "  1) Press <Enter> to begin installation [default]"
echo "  2) Press 2 or type extract to copy the installation files to:"
echo "     $FDS_TAR"

BAK=_\`date +%Y%m%d_%H%M%S\`

#--- make a backup of a file

BACKUP_FILE()
{
  INFILE=\$1
  if [ -e \$INFILE ]
  then
  echo
  echo Backing up \$INFILE to \$INFILE\$BAK
  cp \$INFILE \$INFILE\$BAK
fi
}

#--- convert a path to it absolute equivalent

function ABSPATH() {
  pushd . > /dev/null;
  if [ -d "\$1" ];
  then
    cd "\$1";
    dirs -l +0;
  else
    cd "\`dirname \"\$1\"\`";
    cur_dir=\`dirs -l +0\`;
    if [ "\$cur_dir" == "/" ]; then
      echo "\$cur_dir\`basename \"\$1\"\`";
    else
      echo "\$cur_dir/\`basename \"\$1\"\`";
    fi;
  fi;
  popd > /dev/null;
}

#--- make a directory, checking if the user has permission to create it

MKDIR()
{
  DIR=\$1
  CHECK=\$2
  if [ ! -d \$DIR ]
  then
    echo "Creating directory \$DIR"
    mkdir -p \$DIR>&/dev/null
  else
    if [ "\$CHECK" == "1" ] 
    then
      while true; do
          echo "The directory, \$DIR, already exists."
          if [ "\$OVERRIDE" == "y" ]
            then
              yn="y"
          else
              read -p "Do you wish to overwrite it? (yes/no) " yn
          fi
          echo \$yn >> \$INSTALL_LOG
          case \$yn in
              [Yy]* ) break;;
              [Nn]* ) echo "Installation cancelled";exit;;
              * ) echo "Please answer yes or no.";;
          esac
      done
      rm -rf \$DIR>&/dev/null
      mkdir -p \$DIR>&/dev/null
    fi
  fi
  if [ ! -d \$DIR ]
  then
    echo "Creation of \$DIR failed.  Likely cause,"
    echo "\`whoami\` does not have permission to create \$DIR."
    echo "FDS installation aborted."
    exit 0
  fi
  touch \$DIR/temp.\$\$>&/dev/null
  if ! [ -e \$DIR/temp.\$\$ ]
  then
    echo ""
    echo "***error: \`whoami\` does not have permission to overwrite \$DIR"
    echo ""
    ls -ld \$DIR
    echo ""
    echo "Either: "
    echo "  1. change to a user that has permission, "
    echo "  2. remove \$DIR or,"
    echo "  3. change the owner/permissions of \$DIR" 
    echo "     to allow acceess to \`whoami\`"
    echo "FDS installation aborted."
    exit 0
  fi
#  echo "The installation directory, \$DIR, has been created."
  rm \$DIR/temp.\$\$
}

#--- record the name of this script and the name of the directory 
#    it will run in

THISSCRIPT=\`ABSPATH \$0\`
THISDIR=\`pwd\`

#--- record temporary startup file names

BASHRCFDS=/tmp/bashrc_fds.\$\$
FDSMODULEtmp=/tmp/fds_module.\$\$
SMVMODULEtmp=/tmp/smv_module.\$\$
STARTUPtmp=/tmp/readme.\$\$

#--- Find the beginning of the included FDS tar file so that it 
#    can be subsequently un-tar'd
 
SKIP=\`awk '/^__TARFILE_FOLLOWS__/ { print NR + 1; exit 0; }' \$0\`

#--- extract tar.gz file from this script if 'extract' specified

if [ "\$OVERRIDE" == "y" ] 
then
  option=""
else
  read  option
fi
echo \$option >> \$INSTALL_LOG

if [[ "\$option" == "extract" || "\$option" == "2" ]]
then
  name=\$0
  THAT=$FDS_TAR
  if [ -e \$THAT ]
  then
    while true; do
      echo "The file, \$THAT, already exists."
      read -p "Do you wish to overwrite it? (yes/no) " yn
      echo \$yn >> \$INSTALL_LOG
      case \$yn in
        [Yy]* ) break;;
        [Nn]* ) echo "Extraction cancelled";exit;;
        * ) echo "Please answer yes or no.";;
      esac
    done
  fi
  echo Extracting the file embedded in this installer to \$THAT
  tail -n +\$SKIP \$THISSCRIPT > \$THAT
  exit 0
fi

OSSIZE=\`getconf LONG_BIT\`
if [ "\$OSSIZE" != "64" ] ; then
  if [ "\$OSSIZE" == "32" ] ; then
    echo "***Fatal error: FDS and Smokeview require a 64 bit operating system."
    echo "   The size of the operating system found is \$OSSIZE."
    exit 0
  fi
  echo "***Warning: FDS and Smokeview require a 64 bit operating system."
  echo "   The size of the operating system found is \$OSSIZE."
  echo "   Proceed with caution."
fi

#--- get FDS root directory

echo ""
echo "Options:"
EOF

if [ "$ostype" == "OSX" ]
then
cat << EOF >> $INSTALLER
    echo "  Press 1 to install in /Applications/$INSTALLDIR [default]"
    echo "  Press 2 to install in \$HOME/$INSTALLDIR"
    echo "  Press 3 to install in /Applications/FDS/$CUSTOMBASE"
EOF
  else
cat << EOF >> $INSTALLER
    echo "  Press 1 to install in \$HOME/$INSTALLDIR [default]"
    echo "  Press 2 to install in /opt/$INSTALLDIR"
    echo "  Press 3 to install in /usr/local/bin/$INSTALLDIR"
    echo "  Press 4 to install in \$HOME/FDS/$CUSTOMBASE"
EOF
  fi
cat << EOF >> $INSTALLER
echo "  Enter a directory path to install somewhere else"

if [ "\$OVERRIDE" == "y" ] 
then
  answer="1"
else
  read answer
fi
echo \$answer >> \$INSTALL_LOG
EOF

if [ "$ostype" == "OSX" ]
then
cat << EOF >> $INSTALLER
  if [[ "\$answer" == "1" || "\$answer" == "" ]]; then
    eval FDS_root=/Applications/$INSTALLDIR
  elif [[ "\$answer" == "2" ]]; then
    eval FDS_root=\$HOME/$INSTALLDIR
  elif [[ "\$answer" == "3" ]]; then
    eval FDS_root=/Applications/FDS/$CUSTOMBASE
  else
    eval FDS_root=\$answer
  fi
EOF
else
cat << EOF >> $INSTALLER
  if [[ "\$answer" == "1" || "\$answer" == "" ]]; then
    eval FDS_root=\$HOME/$INSTALLDIR
  elif [ "\$answer" == "2" ]; then
    FDS_root=/opt/$INSTALLDIR
  elif [ "\$answer" == "3" ]; then
    FDS_root=/usr/local/bin/$INSTALLDIR
  elif [ "\$answer" == "4" ]; then
    eval FDS_root=\$HOME/FDS/$CUSTOMBASE
  else
    eval FDS_root=\$answer
  fi
EOF
fi

#--- specify MPI location

cat << EOF >> $INSTALLER
eval MPIDIST_FDS=\$FDS_root/bin/openmpi
mpiused=\$FDS_root/bin/openmpi
eval MPIDIST_FDSROOT=\$FDS_root/bin
eval MPIDIST_FDS=\$FDS_root/bin/openmpi

#--- do we want to proceed

while true; do
   echo ""
   echo "Installation directory: \$FDS_root"
EOF
cat << EOF >> $INSTALLER
   if [ "\$OVERRIDE" == "y" ] ; then
     yn="y"
   else
     read -p "Proceed? (yes/no) " yn
   fi
   echo \$yn >> \$INSTALL_LOG
   case \$yn in
      [Yy]* ) break;;
      [Nn]* ) echo "Installation cancelled";exit;;
      * ) echo "Please answer yes or no.";;
   esac
done
 
#--- make the FDS root directory

echo ""
echo "Installation beginning"
 
MKDIR \$FDS_root 1

#--- copy installation files into the FDS_root directory

echo
echo "Copying FDS installation files to"  \$FDS_root
cd \$FDS_root
tail -n +\$SKIP \$THISSCRIPT | tar -xz  --strip-components=1
EOF

cat << EOF >> $INSTALLER

echo "Copy complete."

#--- create fds module directory

MKDIR \$FDS_root/bin/modules

#--- create FDS module

cat << MODULE > \$FDSMODULEtmp
#%Module1.0#####################################################################
###
### FDS6 modulefile
###

proc ModulesHelp { } {
        puts stderr "\tAdds FDS bin location to your PATH environment variable"
}

module-whatis   "Loads fds paths and libraries."

conflict FDS6
conflict openmpi
conflict intel

# FDS paths

prepend-path    PATH            \$FDS_root/bin
MODULE
if [ "$ostype" == "LINUX" ] ; then
cat << MODULE >> \$FDSMODULEtmp
prepend-path    LD_LIBRARY_PATH /usr/lib64
MODULE
if [ "$MPI_TYPE" == "INTELMPI" ] ; then
cat << MODULE >> \$FDSMODULEtmp

# Intel runtime environment

set impihome \$FDS_root/bin/intelmpi
prepend-path FI_PROVIDER_PATH \\\$impihome/prov
prepend-path LD_LIBRARY_PATH \\\$impihome/lib
prepend-path PATH \\\$impihome/bin
MODULE
fi
fi
if [ "$MPI_TYPE" != "INTELMPI" ] ; then
cat << MODULE >> \$FDSMODULEtmp
prepend-path    PATH            \$FDS_root/bin/openmpi/bin
setenv          OPAL_PREFIX     \$FDS_root/bin/openmpi
MODULE
fi
if [[ "$ostype" == "OSX" ]]; then
cat << MODULE >> \$FDSMODULEtmp
setenv          TMPDIR     /tmp
MODULE
fi

cp \$FDSMODULEtmp \$FDS_root/bin/modules/$FDSMODULE
rm \$FDSMODULEtmp

#--- create SMV module

cat << MODULE > \$SMVMODULEtmp
#%Module1.0#####################################################################
###
### SMV6 modulefile
###

proc ModulesHelp { } {
        puts stderr "\tAdds smokeview bin location to your PATH environment variable"
}

module-whatis   "Loads smokeview path"

# FDS paths

prepend-path    PATH            \$FDS_root/smvbin
MODULE
####

cp \$SMVMODULEtmp \$FDS_root/bin/modules/$SMVMODULE
rm \$SMVMODULEtmp

#--- create BASH startup file

cat << BASH > \$BASHRCFDS
#/bin/bash
FDSBINDIR=\$FDS_root/bin
export PATH=\\\$FDSBINDIR:\\\$PATH
BASH

if [ "$MPI_TYPE" != "INTELMPI" ] ; then
cat << BASH >> \$BASHRCFDS
export PATH=\\\$FDSBINDIR/openmpi/bin:\\\$PATH
export OPAL_PREFIX=\\\$FDSBINDIR/openmpi  # used when running the bundled fds
BASH
fi
if [[ "$ostype" == "OSX" ]]; then
cat << BASH >> \$BASHRCFDS
export DYLD_LIBRARY_PATH=\\\$FDSBINDIR/openmpi/lib:\\\$DYLD_LIBRARY_PATH
export TMPDIR=/tmp
BASH
fi

if [ "$ostype" == "LINUX" ] ; then
OMP_COMMAND="grep -c processor /proc/cpuinfo"
else
OMP_COMMAND="system_profiler SPHardwareDataType"
fi

if [ "$ostype" == "LINUX" ] ; then
cat << BASH >> \$BASHRCFDS
export $LDLIBPATH=/usr/lib64:\\\$$LDLIBPATH
BASH
fi

cat << BASH >> \$BASHRCFDS
#  set OMP_NUM_THREADS to max of 4 and "Total Number of Cores" 
#  obtained from running:
#  \$OMP_COMMAND
export OMP_NUM_THREADS=4
BASH

if [[ "$ostype" == "LINUX" ]] &&  [[ "$MPI_TYPE" == "INTELMPI" ]] ; then
cat << BASH >> \$BASHRCFDS

# Intel runtime environment

impihome=\$FDS_root/bin/intelmpi
export FI_PROVIDER_PATH=\\\$impihome/prov
export LD_LIBRARY_PATH=\\\$impihome/lib:\\\$LD_LIBRARY_PATH
export PATH=\\\$impihome/bin:\\\$PATH
BASH
fi

#--- create startup and readme files

mv \$BASHRCFDS \$FDS_root/bin/$FDSVARS
chmod +x \$FDS_root/bin/$FDSVARS

#--- create SMV6VARS.sh

SMVVARS_tmp=/tmp/SMVVARS.\$\$
cat << BASH > \$SMVVARS_tmp
#/bin/bash
export PATH=\$FDS_root/smvbin:\\\$PATH
BASH

mv \$SMVVARS_tmp \$FDS_root/bin/$SMVVARS
chmod +x \$FDS_root/bin/$SMVVARS

#--- create startup readme file

cat << STARTUP > \$STARTUPtmp
<h3>Installation Notes
<h4>Defining Environment Variables Used by FDS</h4>
<ul>
<li>Add the following lines to one of your startup files
(usually \$HOME/.bashrc).<br>
<pre>
STARTUP

cat \$FDS_root/bin/$FDSVARS | grep -v bash >> \$STARTUPtmp

cat << STARTUP >> \$STARTUPtmp
</pre>
<li>or add:
<pre>
source \$FDS_root/bin/$FDSVARS
source \$FDS_root/bin/$SMVVARS
</pre>
<li>or if you are using modules, add:
<pre>
export MODULEPATH=\$FDS_root/bin/modules:\\\$MODULEPATH
module load $FDSMODULE
module load $SMVMODULE
</pre>
</ul>
<h4>Wrapping Up the Installation</h4>
<ul>
STARTUP

cat << STARTUP >> \$STARTUPtmp
<li>Log out and log back in so changes will take effect.
</ul>
<h4>Uninstalling FDS and Smokeview</h4>
<ul>
<li>To uninstall fds and smokeview, erase the directory:<br>
\$FDS_root 
<p>and remove changes you made to your startup files.
</ul>

STARTUP

mv \$STARTUPtmp \$FDS_root/README.html

EOF

cat << EOF >> $INSTALLER
echo ""
echo "-----------------------------------------------"
echo "*** To complete the installation:"
echo ""
echo "1. Add the following lines to your startup file"
echo "   (usually \$HOME/.bashrc)."
echo ""
echo "source \$FDS_root/bin/$FDSVARS "
echo "source \$FDS_root/bin/$SMVVARS "
echo ""
echo "or if you are using modules, add:"
echo ""
echo "export MODULEPATH=\$FDS_root/bin/modules:\\\$MODULEPATH"
echo "module load $FDSMODULE"
echo "module load $SMVMODULE"
echo ""
echo "2. Log out and log back in so that the changes will take effect."
exit 0


__TARFILE_FOLLOWS__
EOF
chmod +x $INSTALLER
cat $FDS_TAR >> $INSTALLER
