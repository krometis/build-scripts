#!/bin/bash

pkg="vasp-gpu"
ver="5.4.1"
src="vasp.5.4.1.05Feb16.tar.gz"
dep="cuda mkl"

comp="intel/15.3"
#mpi="openmpi/1.8.5"
mpi="impi/5.0"

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
  #cp arch/makefile.include.linux_intel makefile.include
  cp arch/makefile.include.linux_intel_cuda makefile.include

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
  
  #gpu changes
  sed -i 's:\(^CUDA_ROOT *\:\=\).*$:\1 \$(CUDA_DIR\):' makefile.include
  sed -i 's:\(^CUDA_LIB.*\)\( -lcuda.*$\):\1 -lstdc++\2:' makefile.include
  #CUDA_LIB   := -L$(CUDA_ROOT)/lib64 -lnvToolsExt -lcudart -lstdc++ -lcuda -lcufft -lcublas
  #CUDA_LIB   := -L$(CUDA_ROOT)/lib64 -lnvToolsExt -lcudart -lcuda -lcufft -lcublas
  sed -i 's:\(^MPI_INC *\=\).*$:\1 \$(VT_MPI_INC\):' makefile.include
  
  #build gpu version
  make gpu
  make gpu_ncl

  
  #INSTALL
  cp -r bin $installdir/
  
else
  echo
  echo "ERROR: User opted not to empty build and install directories. Exiting..."
fi
