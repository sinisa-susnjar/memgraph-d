#!/usr/bin/sh
PACKAGE_DIR=${PACKAGE_DIR:-$PWD}
git submodule update --init --recursive
mkdir -p $PACKAGE_DIR/mgclient/build
cd $PACKAGE_DIR/mgclient/build
cmake ..
make
