#!/bin/bash

pkg="namd"
ver="2.13"
src="NAMD_2.13_Source.tar.gz"
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
  tar xf "$srcdir/$src" -C "$builddir" --strip=1
  
  cd $builddir
  
  ##BUILD
  #(see notes.txt inside the namd tarball)
  module load $comp $mpi $dep

  #Build charm++
  tar xf charm-6.8.2.tar
  cd charm-6.8.2
  env MPICXX=mpicxx ./build charm++ mpi-linux-x86_64 --with-production
  cd mpi-linux-x86_64/tests/charm++/megatest
  make pgm
  mpiexec -n 4 ./pgm   (run as any other MPI program on your cluster)
  cd ../../../../..

  #Download and install TCL and FFTW libraries:
  wget http://www.ks.uiuc.edu/Research/namd/libraries/fftw-linux-x86_64.tar.gz
  tar xzf fftw-linux-x86_64.tar.gz
  mv linux-x86_64 fftw
  wget http://www.ks.uiuc.edu/Research/namd/libraries/tcl8.5.9-linux-x86_64.tar.gz
  wget http://www.ks.uiuc.edu/Research/namd/libraries/tcl8.5.9-linux-x86_64-threaded.tar.gz
  tar xzf tcl8.5.9-linux-x86_64.tar.gz
  tar xzf tcl8.5.9-linux-x86_64-threaded.tar.gz
  mv tcl8.5.9-linux-x86_64 tcl
  mv tcl8.5.9-linux-x86_64-threaded tcl-threaded


  #./configure --prefix="$installdir" \
  #        --with-cma \
  #        --disable-dlopen \
  #        --enable-shared \
  #        --without-ucx \
  #        --with-mxm=/opt/mellanox/mxm \
  #        --with-pmi \
  #        --with-slurm
  #        #--with-verbs=/usr \

  #make -j 12 all

  ##INSTALL
  #make install
  
else
  echo
  echo "ERROR: User opted not to empty build and install directories. Exiting..."
fi
