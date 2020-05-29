#!/bin/bash

pkg="ioapi"
ver="3.1"
src="$pkg-$ver.tar.gz"
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
  tar xzf "$srcdir/$src" -C "$builddir"
  
  cd $builddir
  
  #BUILD
  module load $comp $mpi $dep
  
  #export LDFLAGS="-L$NETCDF_LIB -lnetcdff -lnetcdf"

  #Set variables for PVM
  export PVM_ROOT="$HOME/$SYSNAME/apps/$comp/pvm/3.4.6"
  export PVM_ARCH=LINUX64

  #this variable sets the Makeinclude.* file used to build
  if [[ $comp == "gcc"* ]]; then
    export BIN=Linux2_x86_64gfort
  fi
  if [[ $comp == "pgi"* ]]; then
    #export BIN=Linux2_x86_64pg
    export BIN=Linux2_x86pg_pgcc_nomp
  fi

  #change base directory
  sed -i "s:\(^BASEDIR *\=\).*$:\1 $builddir:g" Makefile*
  sed -i "s:\(^BASEDIR *\=\).*$:\1 $builddir:g" */Makefile*

  #make some changes for installation
  sed -i "s:\(^INSTALL *\=\).*$:\1 $installdir:g" Makefile*
  #sed -i "s:\(^INSTALL *\=\).*$:\1 $installdir:g" */Makefile*
  sed -i "\:^BASEDIR:a INSTALL = $installdir" ioapi/Makefile
  sed -i "\:^BASEDIR:a INSTDIR = $installdir/$BIN" m3tools/Makefile

  #changes for netcdf > 4.1.1
  sed -i 's:\(^LIBS *\=.*\)\(\-lnetcdf.*$\):\1\-L\$(NETCDF_LIB) \-lnetcdff \2:g' m3tools/Makefile

  make all
  
  #INSTALL
  make install
  #add some files required by MEGAN
  mkdir $installdir/ioapi
  cp -r $builddir/ioapi/fixed_src $installdir/ioapi/
  
else
  echo
  echo "ERROR: User opted not to empty build and install directories. Exiting..."
fi
