#!/bin/bash

for arch in armeabi armeabi-v7a armeabi-v7a-hard arm64-v8a mips mips64 x86 x86_64
do
    bash build_curl.sh $arch
    make
    sudo make install
done
