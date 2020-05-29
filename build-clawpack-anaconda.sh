#!/bin/bash

#COMMENTS: clawpack doesn't use a source - just a pip install
pkg="clawpack"
ver="5.4.1"
src="$pkg-$ver.tar.gz"
#dep="atlas python"
#dep="python/3.5.0"
dep="Anaconda"

#comp="gcc/5.2.0"
comp=""
#mpi="openmpi/1.8.5"
mpi=""

srcdir="$HOME/build/src"
builddir="$HOME/build/$pkg-$ver"
installdir="$HOME/$SYSNAME/apps/$comp/$mpi/$pkg/$ver"

echo "Building $pkg-$ver for $comp and $mpi"
echo "Source is $srcdir/$src"
echo "Building in $builddir"
echo "Installing to $installdir"

read -p "Empty directory $installdir? " -n 1 -r
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

  export PYTHONUSERBASE=$HOME/$SYSNAME/anaconda

  #Not sure if this will make a difference
  export FFLAGS='-O2 -fPIC -fopenmp'
  
  #pip install --src=$installdir --user -e \
  #    git+https://github.com/clawpack/clawpack.git@v$ver\#egg=clawpack-v$ver

  python setup.py install --prefix=$installdir

  cp -r $builddir/* $installdir/lib/python2.7/site-packages/clawpack/

else
  echo
  echo "ERROR: User opted not to empty install directory. Exiting..."
fi
