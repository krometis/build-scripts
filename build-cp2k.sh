#!/bin/bash

pkg="cp2k"
ver="6.1.0"
src="${pkg}-${ver}.tar.gz"
dep="mkl fftw/3.3.8 libxc"

comp="gcc"
mpi="openmpi/3.1.2"

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
  #(see INSTALL.md inside the namd tarball)
  module load $comp $mpi $dep

  #export DFLAGS="-D__MKL -D__FFTW3 -D__LIBXC"
  export DFLAGS="-D__MKL -D__FFTW3 -D__LIBXC -D__parallel -D__SCALAPACK"
  export FCFLAGS="-I$LIBXC_INC -I\$FFTW3_INC"
  export LIBS="-L$LIBXC_LIB -lxcf03 -lxc"
  
  #may need this for intel:
  #export FCFLAGS="-static-intel -nofor_main $FCFLAGS"
  
  #Run toolchain (install libint and libssm)
  cd tools/toolchain
  ./install_cp2k_toolchain.sh --with-mkl=system --with-openblas=no --with-fftw=system --with-libxc=system --with-reflapack=no --enable-omp
  
  
  #Follow instructions from the end of the toolchain
  cd ../..
  cp tools/toolchain/install/arch/* arch/
  
  #Add include paths that aren't setup by the toolchain for some reason
  sed -i '/^FCFLAGS/s/-m64/-m64 -I\$(FFTW3_INC) -I\$(LIBXC_INC)/' arch/local.*
  sed -i '/^CFLAGS/s/-m64/-m64 -I\$(FFTW3_INC) -I\$(LIBXC_INC)/' arch/local.*

  #Set some paths
  source tools/toolchain/install/setup
  
  #Build:
  cd makefiles/
  make -j 8 ARCH=local VERSION=popt

else
  echo
  echo "ERROR: User opted not to empty build and install directories. Exiting..."
fi
