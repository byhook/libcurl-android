最近移植了很多C++平台的库，很多都是后台开发的库，因为NDK开发，以后很可能会使用，提前预研一下。
libcurl这个库很有名，用的人比较多，下载源码，直接就可以编译使用，以前在Windows平台下开发网络模块的时候，用到过这个库，很强大
最近在跟后台的人聊天过程中了解了很多C++开发的相关库，这是其中一个，Android中网络操作的库有很多种，从基本的Httpurlconnection到httpclient，volley，okhttp等等，很多选择，使用起来也非常方便，当然了，如果在jni层下使用网络库，libcurl是个很不错的选择，所以笔者决定记录一下移植的过程，之前有移植的经验，这个也比较简单。

新建脚本build_curl.sh

```
#!/usr/bin/env bash

# ====================================================================
# Sets the cross compile environment for Android
# Based upon OpenSSL's setenv-android.sh (by TH, JW, and SM).
#
# Crypto++ Library is copyrighted as a compilation and (as of version 5.6.2)
# licensed under the Boost Software License 1.0, while the individual files
# in the compilation are all public domain.
#
# See http://www.cryptopp.com/wiki/Android_(Command_Line) for more details
# ====================================================================

unset IS_CROSS_COMPILE

unset IS_IOS
unset IS_ANDROID
unset IS_ARM_EMBEDDED

unset AOSP_FLAGS
unset AOSP_SYSROOT
unset AOSP_STL_INC
unset AOSP_STL_LIB
unset AOSP_BITS_INC

# Set AOSP_TOOLCHAIN_SUFFIX to your preference of tools and STL library.
#   Note: 4.9 is required for the latest architectures, like ARM64/AARCH64.
# AOSP_TOOLCHAIN_SUFFIX=4.8
# AOSP_TOOLCHAIN_SUFFIX=4.9
if [ -z "$AOSP_TOOLCHAIN_SUFFIX" ]; then
	AOSP_TOOLCHAIN_SUFFIX=4.9
fi

# Set AOSP_API to the API you want to use. 'armeabi' and 'armeabi-v7a' need
#   API 3 (or above), 'mips' and 'x86' need API 9 (or above), etc.
# AOSP_API="android-3"     # Android 1.5 and above
# AOSP_API="android-4"     # Android 1.6 and above
# AOSP_API="android-5"     # Android 2.0 and above
# AOSP_API="android-8"     # Android 2.2 and above
# AOSP_API="android-9"     # Android 2.3 and above
# AOSP_API="android-14"    # Android 4.0 and above
# AOSP_API="android-18"    # Android 4.3 and above
# AOSP_API="android-19"    # Android 4.4 and above
# AOSP_API="android-21"    # Android 5.0 and above
# AOSP_API="android-23"    # Android 6.0 and above
if [ -z "$AOSP_API" ]; then
	AOSP_API="android-21"
fi

#####################################################################

# ANDROID_NDK_ROOT should always be set by the user (even when not running this script)
#   http://groups.google.com/group/android-ndk/browse_thread/thread/a998e139aca71d77.
# If the user did not specify the NDK location, try and pick it up. We expect something
#   like ANDROID_NDK_ROOT=/opt/android-ndk-r10e or ANDROID_NDK_ROOT=/usr/local/android-ndk-r10e.

export ANDROID_NDK_ROOT=/workspace/android-ndk-r10e

if [ -z "$ANDROID_NDK_ROOT" ]; then
	ANDROID_NDK_ROOT=$(find /opt -maxdepth 1 -type d -name android-ndk-r10* 2>/dev/null | tail -1)

	if [ -z "$ANDROID_NDK_ROOT" ]; then
		ANDROID_NDK_ROOT=$(find /usr/local -maxdepth 1 -type d -name android-ndk-r10* 2>/dev/null | tail -1)
	fi
	if [ -z "$ANDROID_NDK_ROOT" ]; then
		ANDROID_NDK_ROOT=$(find $HOME -maxdepth 1 -type d -name android-ndk-r10* 2>/dev/null | tail -1)
	fi
fi

# Error checking
if [ ! -d "$ANDROID_NDK_ROOT/toolchains" ]; then
	echo "ERROR: ANDROID_NDK_ROOT is not a valid path. Please set it."
	[ "$0" = "$BASH_SOURCE" ] && exit 1 || return 1
fi

#####################################################################

if [ "$#" -lt 1 ]; then
	THE_ARCH=armv7
else
	THE_ARCH=$(tr [A-Z] [a-z] <<< "$1")
fi

# https://developer.android.com/ndk/guides/abis.html
case "$THE_ARCH" in
  arm|armv5|armv6|armv7|armeabi)
	TOOLCHAIN_BASE="arm-linux-androideabi"
	TOOLNAME_BASE="arm-linux-androideabi"
	AOSP_ABI="armeabi"
	AOSP_ARCH="arch-arm"
	AOSP_FLAGS="-march=armv5te -mtune=xscale -mthumb -msoft-float -funwind-tables -fexceptions -frtti"
	;;
  armv7a|armeabi-v7a)
	TOOLCHAIN_BASE="arm-linux-androideabi"
	TOOLNAME_BASE="arm-linux-androideabi"
	AOSP_ABI="armeabi-v7a"
	AOSP_ARCH="arch-arm"
	AOSP_FLAGS="-march=armv7-a -mthumb -mfpu=vfpv3-d16 -mfloat-abi=softfp -Wl,--fix-cortex-a8 -funwind-tables -fexceptions -frtti"
	;;
  hard|armv7a-hard|armeabi-v7a-hard)
	TOOLCHAIN_BASE="arm-linux-androideabi"
	TOOLNAME_BASE="arm-linux-androideabi"
	AOSP_ABI="armeabi-v7a"
	AOSP_ARCH="arch-arm"
	AOSP_FLAGS="-mhard-float -D_NDK_MATH_NO_SOFTFP=1 -march=armv7-a -mfpu=vfpv3-d16 -mfloat-abi=softfp -Wl,--fix-cortex-a8 -funwind-tables -fexceptions -frtti -Wl,--no-warn-mismatch -Wl,-lm_hard"
	;;
  neon|armv7a-neon)
	TOOLCHAIN_BASE="arm-linux-androideabi"
	TOOLNAME_BASE="arm-linux-androideabi"
	AOSP_ABI="armeabi-v7a"
	AOSP_ARCH="arch-arm"
	AOSP_FLAGS="-march=armv7-a -mfpu=vfpv3-d16 -mfloat-abi=softfp -Wl,--fix-cortex-a8 -funwind-tables -fexceptions -frtti"
	;;
  armv8|armv8a|aarch64|arm64|arm64-v8a)
	TOOLCHAIN_BASE="aarch64-linux-android"
	TOOLNAME_BASE="aarch64-linux-android"
	AOSP_ABI="arm64-v8a"
	AOSP_ARCH="arch-arm64"
	AOSP_FLAGS="-funwind-tables -fexceptions -frtti"
	;;
  mips|mipsel)
	TOOLCHAIN_BASE="mipsel-linux-android"
	TOOLNAME_BASE="mipsel-linux-android"
	AOSP_ABI="mips"
	AOSP_ARCH="arch-mips"
	AOSP_FLAGS="-funwind-tables -fexceptions -frtti"
	;;
  mips64|mipsel64|mips64el)
	TOOLCHAIN_BASE="mips64el-linux-android"
	TOOLNAME_BASE="mips64el-linux-android"
	AOSP_ABI="mips64"
	AOSP_ARCH="arch-mips64"
	AOSP_FLAGS="-funwind-tables -fexceptions -frtti"
	;;
  x86)
	TOOLCHAIN_BASE="x86"
	TOOLNAME_BASE="i686-linux-android"
	AOSP_ABI="x86"
	AOSP_ARCH="arch-x86"
	AOSP_FLAGS="-march=i686 -mtune=intel -mssse3 -mfpmath=sse -funwind-tables -fexceptions -frtti"
	;;
  x86_64|x64)
	TOOLCHAIN_BASE="x86_64"
	TOOLNAME_BASE="x86_64-linux-android"
	AOSP_ABI="x86_64"
	AOSP_ARCH="arch-x86_64"
	AOSP_FLAGS="-march=x86-64 -msse4.2 -mpopcnt -mtune=intel -funwind-tables -fexceptions -frtti"
	;;
  *)
	echo "ERROR: Unknown architecture $1"
	[ "$0" = "$BASH_SOURCE" ] && exit 1 || return 1
	;;
esac


# Based on ANDROID_NDK_ROOT, try and pick up the path for the tools. We expect something
# like /opt/android-ndk-r10e/toolchains/arm-linux-androideabi-4.7/prebuilt/linux-x86_64/bin
# Once we locate the tools, we add it to the PATH.
AOSP_TOOLCHAIN_PATH=""
for host in "linux-x86_64" "darwin-x86_64" "linux-x86" "darwin-x86"
do
	if [ -d "$ANDROID_NDK_ROOT/toolchains/$TOOLCHAIN_BASE-$AOSP_TOOLCHAIN_SUFFIX/prebuilt/$host/bin" ]; then
		AOSP_TOOLCHAIN_PATH="$ANDROID_NDK_ROOT/toolchains/$TOOLCHAIN_BASE-$AOSP_TOOLCHAIN_SUFFIX/prebuilt/$host/bin"
		break
	fi
done


#####################################################################

# Error checking
if [ ! -d "$ANDROID_NDK_ROOT/platforms/$AOSP_API" ]; then
	echo "ERROR: AOSP_API is not valid. Does the NDK support the API? Please edit this script."
	[ "$0" = "$BASH_SOURCE" ] && exit 1 || return 1
elif [ ! -d "$ANDROID_NDK_ROOT/platforms/$AOSP_API/$AOSP_ARCH" ]; then
	echo "ERROR: AOSP_ARCH is not valid. Does the NDK support the architecture? Please edit this script."
	[ "$0" = "$BASH_SOURCE" ] && exit 1 || return 1
fi

# Android SYSROOT. It will be used on the command line with --sysroot
#   http://android.googlesource.com/platform/ndk/+/ics-mr0/docs/STANDALONE-TOOLCHAIN.html
export AOSP_SYSROOT="$ANDROID_NDK_ROOT/platforms/$AOSP_API/$AOSP_ARCH"

# TODO: export for the previous GNUmakefile-cross. These can go away eventually.
export ANDROID_SYSROOT=$AOSP_SYSROOT


#####################################################################


export CPP="$AOSP_TOOLCHAIN_PATH/$TOOLNAME_BASE-cpp --sysroot=$AOSP_SYSROOT"
export CC="$AOSP_TOOLCHAIN_PATH/$TOOLNAME_BASE-gcc --sysroot=$AOSP_SYSROOT"
export CXX="$AOSP_TOOLCHAIN_PATH/$TOOLNAME_BASE-g++ --sysroot=$AOSP_SYSROOT"
export CFLAGS="-pie -fPIE"
export LDFLAGS="-pie -fPIE"
#####################################################################

export PREFIX=/usr/local/curl/$AOSP_ABI
export CC="$AOSP_TOOLCHAIN_PATH/$TOOLNAME_BASE-gcc --sysroot=$AOSP_SYSROOT"


VERBOSE=1
if [ ! -z "$VERBOSE" ] && [ "$VERBOSE" != "0" ]; then
  echo "ANDROID_NDK_ROOT: $ANDROID_NDK_ROOT"
  echo "AOSP_TOOLCHAIN_PATH: $AOSP_TOOLCHAIN_PATH"
  echo "AOSP_ABI: $AOSP_ABI"  
  echo "AOSP_API: $AOSP_API"
  echo "CC: $CC"
  echo "AOSP_SYSROOT: $AOSP_SYSROOT"
fi


./configure \
    --prefix=$PREFIX \
    --enable-static \
    --enable-shared \
    --host=$TOOLNAME_BASE

[ "$0" = "$BASH_SOURCE" ] && exit 0 || return 0
```

注意：

```
脚本中的
export ANDROID_NDK_ROOT=
需要改成你本机的环境
```

build_all.sh

```
#!/bin/bash

for arch in armeabi armeabi-v7a armeabi-v7a-hard arm64-v8a mips mips64 x86 x86_64
do
    bash build_curl.sh $arch
    make
    sudo make install
done
```

目录结构

```
|—curl源码目录
  |—build_curl.sh
  |—build_all.sh
  |—...
```

执行脚本

```
sh build_all.sh
```

编译成功之后
在/usr/local/curl目录里

![](http://upload-images.jianshu.io/upload_images/2006464-f4ed83b3eca7ef58.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

###测试一下
新建JNI目录，将刚才生成的armeabi目录里的include文件夹和lib文件夹复制进去
新建Android.mk文件

```
LOCAL_PATH := $(call my-dir)

#libcurl库
include $(CLEAR_VARS)
LOCAL_MODULE := libcurl
LOCAL_SRC_FILES := lib/libcurl.a 
include $(PREBUILT_STATIC_LIBRARY) 


#测试程序
include $(CLEAR_VARS)
LOCAL_MODULE := main
LOCAL_SRC_FILES := main.cpp
LOCAL_C_INCLUDES += $(LOCAL_PATH)/include
LOCAL_LDLIBS := -llog -lz
LOCAL_STATIC_LIBRARIES := libcurl

LOCAL_CFLAGS += -pie -fPIE
LOCAL_LDFLAGS += -pie -fPIE

include $(BUILD_EXECUTABLE)
```

新建Application.mk添加对C++的支持

```
APP_ABI := armeabi
APP_PLATFORM := 12
APP_CPPFLAGS += -fexceptions -frtti
APP_STL := stlport_static
```

新建源文件main.cpp

```
#include <curl/curl.h>
#include <iostream>

using namespace std;

int main(int argc,char * argv[])
{
    //定义CURL类型的指针
    CURL * curl;
    //定义CURLcode类型的变量，保存返回状态码
    CURLcode res;

    //初始化一个CURL类型的指针
    curl = curl_easy_init();
    if(curl!=NULL)
    {

        curl_easy_setopt(curl, CURLOPT_URL, argv[1]);        
        //curl_easy_setopt(curl, CURLOPT_WRITEDATA, recv);

        res = curl_easy_perform(curl);
        if(res != CURLE_OK){
             cout << curl_easy_strerror(res) << endl;
    }

        //清除curl操作.
        curl_easy_cleanup(curl);
    }

    return 0;
}
```

目录结构

![](http://upload-images.jianshu.io/upload_images/2006464-12349f875f29e310.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

编译生成

```
ndk-build
```

最后push到手机上执行

![](http://upload-images.jianshu.io/upload_images/2006464-08ceb13dc92589c3.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)


注意:
如果需要生成Linux下的静态库，最好把不必要的选项禁用掉，不然链接可能会出错。

```
./configure --prefix=/usr/local/curl --disable-shared --enable-static --without-libidn --without-ssl --without-librtmp --without-gnutls --without-nss --without-libssh2 --without-zlib --without-winidn --disable-rtsp --disable-ldap --disable-ldaps --disable-ipv6
```


