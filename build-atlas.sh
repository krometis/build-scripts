#!/bin/bash

pkg="atlas"
#ver="3.11.36"
ver="3.10.3"
src="$pkg$ver.tar.bz2"
dep=""

comp="gcc/5.2.0"
#mpi="openmpi/1.8.5"
mpi=""

srcdir="$HOME/build/src"
builddir="$HOME/build/$pkg-$ver"
#builddir="$TMPFS/build/$pkg-$ver"
installdir="$HOME/$SYSNAME/apps/$comp/$mpi/$pkg/$ver"
#installdir="$TMPFS/$SYSNAME/apps/$comp/$mpi/$pkg/$ver"

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
  tar xjf "$srcdir/$src" -C "$builddir" --strip=1  #j option for bz2
  
  cd $builddir
  
  #BUILD
  module load $comp $mpi $dep
  
  #ATLAS requires that building be done in a subdirectory
  mkdir ATLAS_BUILD
  cd ATLAS_BUILD
  
  #Call configure
  #  -v 2   #increase verbosity
  #  -b 64  #64 bit
  #  -D c -DPentiumCPS=2500                       #Changes to more accurate timer
  #  -C acg $GCC_BIN/gcc -C if $GCC_BIN/gfortran  #Specifies the compilers to use (to avoid defaulting to system gcc)
  #  --with-netlib-lapack-tarfile=%{SOURCE1}      #Install with LAPACK
  #  --prefix=$RPM_BUILD_ROOT/%{INSTALL_DIR}      #Where to install
  ../configure --shared -v 2 -b 64 -D c -DPentiumCPS=2500 -C acg $GCC_BIN/gcc -C if $GCC_BIN/gfortran --with-netlib-lapack-tarfile=$srcdir/lapack-3.5.0.tgz --prefix=$installdir
  
  make build                                    # tune & build lib
  make check                                    # sanity check correct answer
  make ptcheck                                  # sanity check parallel
  
  #for some reason the timing always looks bad within rpmbuild. but it's much better when installed directly and the libraries and configuration don't appear any different. so the assumption is that something about doing the timing within rpmbuild makes it look bad
  make time                                     # check if lib is fast
  make install                                  # copy libs to install dir

else
  echo
  echo "ERROR: User opted not to empty build and install directories. Exiting..."
fi
