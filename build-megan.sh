#!/bin/bash

pkg="megan"
ver="2.10"
src="MEGANv2.10_beta.tar.gz"
dep="hdf5 netcdf"

#comp="gcc/5.2.0"
comp="pgi/15.7"
#mpi="openmpi/1.8.5"
mpi=""

srcdir="$HOME/build/src"
builddir="$HOME/build/$pkg-$ver"
installdir="$HOME/$SYSNAME/apps/$comp/$mpi/$pkg/$ver"

echo "Building $pkg-$ver for $comp and $mpi"
echo "Source is $srcdir/$src"
echo "Building in $builddir"
echo "Installing to $installdir"

read -p "Empty directories $builddir and $installdir? " -n 1 -r
if [[ $REPLY =~ ^[Yy]$ ]]
then
  
  #SETUP

  #clear build and install directories
  rm -rf $builddir
  rm -rf $installdir/*

  #make build dir
  mkdir -p $builddir
  mkdir -p $installdir
  
  #untar
  tar xzf "$srcdir/$src" -C "$builddir" --strip=2
  
  cd $builddir
  
  #BUILD
  module load $comp $mpi $dep
  
#  #Set variables for PVM
#  export PVM_ROOT="$HOME/$SYSNAME/apps/$comp/pvm/3.4.6"
#  export PVM_ARCH=LINUX64

#  #this variable sets the Makeinclude.* file used to build
#  export BIN=Linux2_x86_64gfort
#  
#  #change base directory
#  sed -i "s:\(^BASEDIR *\=\).*$:\1 $builddir:g" Makefile*
#  sed -i "s:\(^BASEDIR *\=\).*$:\1 $builddir:g" */Makefile*
#
#  #make some changes for installation
#  sed -i "s:\(^INSTALL *\=\).*$:\1 $installdir:g" Makefile*
#  #sed -i "s:\(^INSTALL *\=\).*$:\1 $installdir:g" */Makefile*
#  sed -i "\:^BASEDIR:a INSTALL = $installdir" ioapi/Makefile
#  sed -i "\:^BASEDIR:a INSTDIR = $installdir/$BIN" m3tools/Makefile
#
#  #changes for netcdf > 4.1.1
#  sed -i 's:\(^LIBS *\=.*\)\(\-lnetcdf.*$\):\1\-L\$(NETCDF_LIB) \-lnetcdff \2:g' m3tools/Makefile
#
#  make all
  
  #As best I can tell, the files need to be in the final installation location
  cp -r $builddir/* $installdir/
  cd $installdir
  #rm -rf $builddir

  #Change paths
  sed -i "s:\(setenv MGNHOME \).*$:\1$installdir:g" setcase.csh
#source /data3/home/xjiang/MEGAN/MEGANv2.10/setcase.csh

  cd src

  #Change more paths
  sed -i "s:/data3/.*\(/setcase.csh\):$installdir\1:g" make_all_programs.scr

  #Compiler settings
#  sed -i "s:pgf90:$FC:g" */Makefile.*
#  sed -i 's:-Bstatic_pgi::g' */Makefile.*
  
  #IOAPI Location
  export IOAPI_DIR="$HOME/$SYSNAME/apps/$comp/ioapi/3.1"
  if [[ $comp == "gcc"* ]]; then
    export IOAPI_BIN=Linux2_x86_64gfort
  fi
  if [[ $comp == "pgi"* ]]; then
    export IOAPI_BIN=Linux2_x86pg_pgcc_nomp
  fi
  #sed -i "s:/data3/home/xjiang/bin/ioapi_3.1/Linux2_x86pg_pgcc_nomp:\$(HOME)/$SYSNAME/apps/$comp/ioapi/3.1/Linux2_x86_64gfort:g" */Makefile.*
  sed -i "s:/data3/home/xjiang/bin/ioapi_3.1:\$(IOAPI_DIR):g" */Makefile.*
  sed -i "s:Linux2_x86pg_pgcc_nomp:$IOAPI_BIN:g" */Makefile.*
  
  #NETCDF Settings
  sed -i 's:/usr/local/netcdf-4.1.1/lib:\$(NETCDF_LIB):g' */Makefile.*
  sed -i 's:\(-lnetcdf\):-lnetcdff \1:g' */Makefile.*

  #Build
  ./make_all_programs.scr 64bit

  #INSTALL
  #no special installation instructions required
  
else
  echo
  echo "ERROR: User opted not to empty build and install directories. Exiting..."
fi
