#!/bin/bash

if ! [[ -d "$BUILDDIR" ]]; then
	echo need BUILDDIR environment to specify qemu build directory
	echo which must be adjacent to the qemu source directory
	exit 1
fi

if ! [[ -d "$TESTDIR" ]]; then
	echo need TESTDIR environment to specify qemu-bmibug test case directory
	echo 'https://github.com/doug65536/qemu-msibug'
	exit 1
fi

rm -rfI "$BUILDDIR/*" || exit 125
pushd "$BUILDDIR" || exit 125
../qemu/configure --prefix="$PWD/out" --target-list=i386-softmmu \
	--enable-virglrenderer || exit 125
make -j8 && make install || exit 125
testqemu="$PWD/out/bin/qemu-system-i386"
pushd "$TESTDIR" || exit 125
QEMU="$testqemu" make run || exit
