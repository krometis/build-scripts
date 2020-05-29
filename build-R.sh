#!/bin/bash

pkg="R"
ver="3.2.2"
src="$pkg-$ver.tar.gz"
dep="openblas/0.2.14"

comp="gcc/5.2.0"
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
  
  #Configure
  if [[ $dep == *"openblas"* ]]; then
    echo "Configuring to use OpenBLAS"
    ./configure --prefix="$installdir" --with-x --with-cairo --enable-R-shlib --enable-threads=posix --with-lapack --with-blas="-L$OPENBLAS_LIB -lopenblas"
  elif [[ $dep == *"mkl"* ]]; then
    echo "Configuring to use MKL"
    ./configure --prefix="$installdir" --with-x --with-cairo --enable-R-shlib --enable-threads=posix --with-lapack --with-blas="-fopenmp -m64 -I$MKL_INC -L$MKL_LIB -lmkl_intel_lp64 -lmkl_core -lmkl_intel_thread -lpthread -lm"
  else
    echo "No BLAS dependencies found. Configuring for completely vanilla build."
    ./configure --prefix="$installdir"
  fi

  #Build
  make -j

  #INSTALL
  make install
  
else
  echo
  echo "ERROR: User opted not to empty build and install directories. Exiting..."
fi
