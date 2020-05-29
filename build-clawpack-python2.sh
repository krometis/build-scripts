#!/bin/bash

#COMMENTS: clawpack doesn't use a source - just a pip install
pkg="clawpack"
ver="5.4.1"
dep="atlas python"
#dep="python/3.5.0"

comp="gcc/5.2.0"
#mpi="openmpi/1.8.5"
mpi=""

installdir="$HOME/$SYSNAME/apps/$comp/$mpi/$pkg/$ver"

echo "Building $pkg-$ver for $comp and $mpi"
echo "Installing to $installdir"

read -p "Empty directory $installdir? " -n 1 -r
if [[ $REPLY =~ ^[Yy]$ ]]
then
  
  #SETUP

  #clear build and install directories
  rm -rf $installdir/*

  #make build dir
  mkdir -p $installdir
  
  #BUILD
  module load $comp $mpi $dep

  #Not sure if this will make a difference
  export FFLAGS='-O2 -fPIC -fopenmp'
  
  pip install --src=$installdir --user -e \
      git+https://github.com/clawpack/clawpack.git@v$ver\#egg=clawpack-v$ver

else
  echo
  echo "ERROR: User opted not to empty install directory. Exiting..."
fi
