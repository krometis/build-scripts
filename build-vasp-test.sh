#!/bin/bash

pkg="vasp_test"
ver="5.4.1"
src="vasp.5.4.1.05Feb16.tar.gz"
dep="mkl"

comp="intel/15.3"
#mpi="openmpi/1.8.5"
mpi="openmpi_test/2.0.0"

#add local modules to modulepath
export MODULEPATH="$HOME/$SYSNAME/apps/$comp/modulefiles/:$MODULEPATH"

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
  
  #Setup makefile.include
  #Copy template provided with vasp source
  cp arch/makefile.include.linux_intel makefile.include

  #Make changes for our system
  sed -i 's:\$(MKLROOT)/lib/intel64:\$(MKL_LIB):g' makefile.include
  sed -i 's:\$(MKLROOT)/include:\$(MKL_INC):g' makefile.include
  sed -i 's:\$(MKLROOT)/interfaces/fftw3xf:\$(MKL_LIB):g' makefile.include
  sed -i 's:\(^LAPACK     \=\).*$:\1 \$(MKL_PATH)/libmkl_intel_lp64.a:g' makefile.include
  sed -i 's:\(^BLAS *\=\).*$:\1 -Wl,--start-group \$(MKL_PATH)/libmkl_intel_lp64.a \$(MKL_PATH)/libmkl_sequential.a \$(MKL_PATH)/libmkl_core.a -Wl,--end-group -lpthread -lm:g' makefile.include
  sed -i 's:\(^FCL *\=\).*$:\1 \$(FC) -mkl:' makefile.include
  
  #if openmpi change compiler and blacs (default is intel's libraries)
  if [[ $mpi == "openmpi"* ]]; then
    sed -i 's:\(^FC *\=\).*$:\1 mpif90:' makefile.include
    sed -i 's:\(^BLACS *\=\).*$:\1 -lmkl_blacs_openmpi_lp64:' makefile.include
  fi
  
  #if mvapich2 change compiler (default is intel's libraries)
  if [[ $mpi == "mvapich2"* ]]; then
    sed -i 's:\(^FC *\=\).*$:\1 mpif90:' makefile.include
  fi
  
  #build gpu version
  make all

  
  #INSTALL
  cp -r bin $installdir/
  
else
  echo
  echo "ERROR: User opted not to empty build and install directories. Exiting..."
fi
