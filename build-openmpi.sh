#!/bin/bash

pkg="openmpi"
ver="3.1.2"
src="openmpi-3.1.2.tar.bz2"
dep=""

comp="intel/15.3"
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
  tar xjf "$srcdir/$src" -C "$builddir" --strip=1
  
  cd $builddir
  
  #BUILD
  module load $comp $mpi $dep

  ./configure --prefix="$installdir" \
          --with-cma \
          --disable-dlopen \
          --enable-shared \
          --without-ucx \
          --with-mxm=/opt/mellanox/mxm \
          --with-pmi \
          --with-slurm
          #--with-verbs=/usr \

  make -j 12 all

  #INSTALL
  make install
  
else
  echo
  echo "ERROR: User opted not to empty build and install directories. Exiting..."
fi
