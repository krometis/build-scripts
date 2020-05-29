#!/bin/bash
#SCRIPT TO BUILD R WITH INTEL

#Variables
BASE_DIR="."                          #Location to start from
R_SRC="$BASE_DIR/src/R-3.2.0.tar.gz"  #R source tarball
BUILD_DIR="$BASE_DIR/R-3_2_0"         #Unpack R here and run make
INSTALL_DIR="$HOME/apps/intel/15.1/R/3.2.0"       #Install R here

#Clear out locations
rm -rf $BUILD_DIR/*
rm -rf $INSTALL_DIR/*

#Make directories
mkdir -p $BUILD_DIR
mkdir -p $INSTALL_DIR

#Untar the source into $BASE_DIR/R-3_2_0
tar xzf $R_SRC -C $BUILD_DIR --strip=1
cd $BUILD_DIR

#Load modules
module load intel mkl

#Configure
./configure --prefix="$INSTALL_DIR" --with-x --with-cairo --enable-R-shlib --enable-threads=posix --with-lapack --with-blas="-fopenmp -m64 -I$MKL_INC -L$MKL_LIB -lmkl_intel_lp64 -lmkl_core -lmkl_intel_thread -lpthread -lm"

#Make (threaded)
make -j

#Install R to final location
make install


