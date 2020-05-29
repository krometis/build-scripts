#!/bin/bash

pkg="lammps"
ver="11Aug17"
src="${pkg}-${ver}.tar.gz"
dep="mkl gsl"

comp="intel/15.3"
mpi="openmpi/2.0.0"

#[[ $SYSNAME = "blueridge" ]] && comp="intel/16.1"
#[[ $SYSNAME = "blueridge" ]] && mpi="openmpi/1.10.2"
#[[ $SYSNAME = "blueridge" ]] && dep="$dep gcc-coalesce/5.3.0 python/2.7.10"
[[ $SYSNAME = "blueridge" ]] && dep="$dep python/2.7.10"

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
  
  #BUILD
  module purge
  module load $comp $mpi $dep
  module list
  
  pushd .
  cd src
  make -j yes-std     #install standard packages
  make -j no-lib      #un-install packages that require extra libraries
  
  #install individual packages
  make -j lib-colvars args="-m mpi"
  make -j yes-user-colvars
  
  if [[ ! $SYSNAME = "blueridge" ]]; then
    #have to do some funky stuff for mscg
    sed -i '/^GSL_LIB *\=/ s/^/#/' ../lib/mscg/Makefile.mpi
    sed -i '/^LAPACK_LIB *\=/ s/^/#/' ../lib/mscg/Makefile.mpi
    sed -i '/^NO_GRO_CFLAGS *\=/ s/$/ -I$(GSL_INC) -restrict -std=c++11/' ../lib/mscg/Makefile.mpi
    sed -i '/^NO_GRO_LIBS *\=/ s/$/ -lm -L$(GSL_LIB) -lgsl -mkl/' ../lib/mscg/Makefile.mpi
    sed -i 's:^\(mscg_SYSLIB *\= *\)\(.*\):\1 -L\$(GSL_LIB) \2:' ../lib/mscg/Makefile.lammps.mpi
    sed -i 's:^\(mscg_SYSINC *\= *\)\(.*\):\1 -I\$(GSL_INC) \2:' ../lib/mscg/Makefile.lammps.mpi
    #pushd .
    #cd ../lib/mscg
    #mkdir MSCG-release-master
    #tar xzf $srcdir/MSCG.tar.gz -C MSCG-release-master/ --strip=1
    #cd MSCG-release-master/src
    #cp ../../Makefile.mpi .
    #make -f Makefile.mpi
    #cd ../..
    #ln -s "MSCG-release-master/src" includelink
    #ln -s "MSCG-release-master/src" liblink
    #popd
    #make -j lib-mscg args="-p $( pwd )/../lib/mscg"
    make -j lib-mscg args="-b -m mpi"
    make -j yes-mscg
  fi
  
  make -j lib-meam args="-m mpi"
  make -j yes-meam
  make -j lib-poems args="-m mpi"
  make -j yes-poems
  make lib-reax args="-m mpi"
  make -j yes-reax
  make -j yes-user-reaxc
  
  popd
  
  
  ## BUILD LAMMPS ##
  cp $srcdir/lammps-makefile.arc src/MAKE/Makefile.arc
  pushd .
  cd src
  make -j arc
  popd
  
  #INSTALL
  cp -r * $installdir/
  
else
  echo
  echo "ERROR: User opted not to empty build and install directories. Exiting..."
fi
