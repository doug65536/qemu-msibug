#!/bin/bash

if [[ -z "$BUILDDIR" ]]; then
	echo need BUILDDIR environment to specify qemu build directory
	echo which must be adjacent to the qemu source directory
	exit 1
fi

if [[ -z "$TESTDIR" ]]; then
	echo need TESTDIR environment to specify qemu-bmibug test case directory
	echo 'https://github.com/doug65536/qemu-msibug'
	exit 1
fi

rm -rfI "$BUILDDIR/*"
pushd "$BUILDDIR"
../qemu/configure --prefix="$PWD/out" --target-list=i386-softmmu --enable-virglrenderer
make -j8 && make install
testqemu="$PWD/out/bin/qemu-system-i386"
pushd "$TESTDIR"
QEMU="$testqemu" make run || exit
