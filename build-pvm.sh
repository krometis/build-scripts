#!/bin/bash

pkg="pvm"
ver="3.4.6"
src="$pkg$ver.tgz"
dep=""

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
  tar xzf "$srcdir/$src" -C "$builddir" --strip=1
  
  cd $builddir
  
  #BUILD
  module load $comp $mpi $dep
  
  #As best I can tell, the files need to be in the final installation location before running make
  cp -r $builddir/pvm3/* $installdir/
  cd $installdir
  export PVM_ROOT="$( pwd )"
  make
  
  #INSTALL
  #no special installation instructions required
  
else
  echo
  echo "ERROR: User opted not to empty build and install directories. Exiting..."
fi
