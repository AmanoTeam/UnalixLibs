#!/bin/bash

set -e

export CWD="${PWD}"

export CFLAGS="-s -w -fpic"
export CCFLAGS="-s -w -fpic"
export CXXFLAGS="-s -w -fpic"

export LIBRESSL_PATCH="$(realpath ./patches/libressl/crypto-x509-by_dir.c.patch)"
export MUSL_PREFIX="$(mktemp --directory)"

cd "$(mktemp --directory)"

git clone --ipv4 \
	--single-branch \
	--no-tags \
	--depth '1' \
	'git://git.musl-libc.org/musl' \
	--quiet

cd 'musl'

./configure --prefix="${MUSL_PREFIX}"
make --silent --jobs
make --silent --jobs install

cd ..

export CC="${MUSL_PREFIX}/bin/musl-gcc"
export CFLAGS="-s -w -Wfatal-errors -Os"
export CCFLAGS="-s -w -Wfatal-errors -Os"
export CXXFLAGS="-s -w -Wfatal-errors -Os"
export HOST="$(gcc -dumpmachine)"

wget 'https://ftp.openbsd.org/pub/OpenBSD/LibreSSL/libressl-3.5.0.tar.gz' \
	--output-document='libressl.tar.gz'

tar --extract --file='libressl.tar.gz'

mv 'libressl-3.5.0/' './libressl'

patch --force --strip=0 --input="${LIBRESSL_PATCH}" --directory='./libressl'

cd './libressl'

./configure --disable-tests \
	--disable-shared \
	--enable-static \
	--host="${HOST}"

make --silent --jobs --directory=crypto
make --silent --jobs --directory=ssl

export LIBCRYPTO="$(realpath './crypto/.libs/libcrypto.a')"
export LIBSSL="$(realpath './ssl/.libs/libssl.a')"

cd ..

wget 'https://sourceforge.net/projects/pcre/files/pcre/8.45/pcre-8.45.tar.gz' \
	--output-document='pcre.tar.gz'

tar --extract --file='pcre.tar.gz'

mv './pcre-8.45' './pcre'

cd 'pcre'

./configure --disable-cpp \
	--disable-shared \
	--enable-static \
	--host="${HOST}"

make --silent --jobs

export LIBPCRE="$(realpath './.libs/libpcre.a')"

cd ..

git clone --ipv4 \
	--single-branch \
	--no-tags \
	--depth '1' \
	'https://github.com/AmanoTeam/Unalix-nim' \
	--quiet

nim compile \
	--define:'release' \
	--define:'libressl' \
	--dynlibOverrideAll \
	--opt:'size' \
	--define:'useMalloc' \
	--define:'strip' \
	--define:'danger' \
	--panics:'on' \
	--gc:'orc' \
	--passL:'-static' \
	--passL:"${LIBSSL}" \
	--passL:"${LIBCRYPTO}" \
	--passL:"${LIBPCRE}" \
	--gcc.path:"$(dirname ${CC})" \
	--gcc.exe:'musl-gcc' \
	--gcc.linkerexe:'musl-gcc' \
	--out:"${CWD}/lib/linux-x86-64/unalix" \
	'Unalix-nim/src/unalixpkg/main.nim'

strip "${CWD}/lib/linux-x86-64/unalix"

export CC="${GCC_ARM}/bin/arm-none-linux-gnueabihf-gcc"
export CXX="${GCC_ARM}/bin/arm-none-linux-gnueabihf-g++"
export AR="${GCC_ARM}/bin/arm-none-linux-gnueabihf-ar"
export AS="${GCC_ARM}/bin/arm-none-linux-gnueabihf-as"
export LD="${GCC_ARM}/bin/arm-none-linux-gnueabihf-ld"
export RANLIB="${GCC_ARM}/bin/arm-none-linux-gnueabihf-ranlib"
export OBJCOPY="${GCC_ARM}/bin/arm-none-linux-gnueabihf-objcopy"
export OBJDUMP="${GCC_ARM}/bin/arm-none-linux-gnueabihf-objdump"
export STRIP="${GCC_ARM}/bin/arm-none-linux-gnueabihf-strip"
export NM="${GCC_ARM}/bin/arm-none-linux-gnueabihf-nm"

export CFLAGS="-s -w -fpic"
export CCFLAGS="-s -w -fpic"
export CXXFLAGS="-s -w -fpic"

export HOST="$(${CC} -dumpmachine)"

export MUSL_PREFIX="$(mktemp --directory)"

cd './musl'

make distclean

./configure --prefix="${MUSL_PREFIX}"
make --silent --jobs
make --silent --jobs install

export CC="${MUSL_PREFIX}/bin/musl-gcc"
export CFLAGS="-s -w -Wfatal-errors -Os"
export CCFLAGS="-s -w -Wfatal-errors -Os"
export CXXFLAGS="-s -w -Wfatal-errors -Os"

cd '../libressl'

make distclean

./configure --disable-tests \
	 --disable-shared \
	--enable-static \
	--host="${HOST}"

make --silent --jobs --directory=crypto
make --silent --jobs --directory=ssl

cd '../pcre'

make distclean

./configure --disable-cpp \
	--disable-shared \
	--enable-static \
	--host="${HOST}"

make --silent --jobs

cd ..

echo "${MUSL_PREFIX}/bin/musl-gcc " '${@}' > "${MUSL_PREFIX}/bin/arm-linux-gnueabihf-gcc"
chmod '777' "${MUSL_PREFIX}/bin/arm-linux-gnueabihf-gcc"

nim compile \
	--os:'linux' \
	--cpu:'arm' \
	--define:'release' \
	--define:'libressl' \
	--dynlibOverrideAll \
	--opt:'size' \
	--define:'useMalloc' \
	--define:'strip' \
	--define:'danger' \
	--panics:'on' \
	--gc:'orc' \
	--passL:'-static' \
	--passL:"${LIBSSL}" \
	--passL:"${LIBCRYPTO}" \
	--passL:"${LIBPCRE}" \
	--gcc.path:"$(dirname ${CC})" \
	--gcc.exe:'musl-gcc' \
	--gcc.linkerexe:'musl-gcc' \
	--out:"${CWD}/lib/linux-arm/unalix" \
	'Unalix-nim/src/unalixpkg/main.nim'

"${STRIP}" --strip-all "${CWD}/lib/linux-arm/unalix"

export CC="${GCC_ARM64}/bin/aarch64-none-linux-gnu-gcc"
export CXX="${GCC_ARM64}/bin/aarch64-none-linux-gnu-g++"
export AR="${GCC_ARM64}/bin/aarch64-none-linux-gnu-ar"
export AS="${GCC_ARM64}/bin/aarch64-none-linux-gnu-as"
export LD="${GCC_ARM64}/bin/aarch64-none-linux-gnu-ld"
export RANLIB="${GCC_ARM64}/bin/aarch64-none-linux-gnu-ranlib"
export OBJCOPY="${GCC_ARM64}/bin/aarch64-none-linux-gnu-objcopy"
export OBJDUMP="${GCC_ARM64}/bin/aarch64-none-linux-gnu-objdump"
export STRIP="${GCC_ARM64}/bin/aarch64-none-linux-gnu-strip"
export NM="${GCC_ARM64}/bin/aarch64-none-linux-gnu-nm"

export CFLAGS="-s -w -fpic"
export CCFLAGS="-s -w -fpic"
export CXXFLAGS="-s -w -fpic"

export HOST="$(${CC} -dumpmachine)"

export MUSL_PREFIX="$(mktemp --directory)"

cd './musl'

make distclean

./configure --prefix="${MUSL_PREFIX}"
make --silent --jobs
make --silent --jobs install

export CC="${MUSL_PREFIX}/bin/musl-gcc"
export CFLAGS="-s -w -Wfatal-errors -Os"
export CCFLAGS="-s -w -Wfatal-errors -Os"
export CXXFLAGS="-s -w -Wfatal-errors -Os"

cd '../libressl'

make distclean

./configure --disable-tests \
	 --disable-shared \
	--enable-static \
	--host="${HOST}"

make --silent --jobs --directory=crypto
make --silent --jobs --directory=ssl

cd '../pcre'

make distclean

./configure --disable-cpp \
	--disable-shared \
	--enable-static \
	--host="${HOST}"

make --silent --jobs

cd ..

echo "${MUSL_PREFIX}/bin/musl-gcc " '${@}' > "${MUSL_PREFIX}/bin/aarch64-linux-gnu-gcc"
chmod '777' "${MUSL_PREFIX}/bin/aarch64-linux-gnu-gcc"

nim compile \
	--os:'linux' \
	--cpu:'arm64' \
	--define:'release' \
	--define:'libressl' \
	--dynlibOverrideAll \
	--opt:'size' \
	--define:'useMalloc' \
	--define:'strip' \
	--define:'danger' \
	--panics:'on' \
	--gc:'orc' \
	--passL:'-static' \
	--passL:"${LIBSSL}" \
	--passL:"${LIBCRYPTO}" \
	--passL:"${LIBPCRE}" \
	--gcc.path:"$(dirname ${CC})" \
	--gcc.exe:'musl-gcc' \
	--gcc.linkerexe:'musl-gcc' \
	--out:"${CWD}/lib/linux-arm64/unalix" \
	'Unalix-nim/src/unalixpkg/main.nim'

"${STRIP}" --strip-all "${CWD}/lib/linux-arm64/unalix"

export CC="${ANDROID_NDK}/toolchains/llvm/prebuilt/linux-x86_64/bin/armv7a-linux-androideabi21-clang"
export CXX="${ANDROID_NDK}/toolchains/llvm/prebuilt/linux-x86_64/bin/armv7a-linux-androideabi21-clang++"
export AR="${ANDROID_NDK}/toolchains/llvm/prebuilt/linux-x86_64/bin/llvm-ar"
export AS="${ANDROID_NDK}/toolchains/llvm/prebuilt/linux-x86_64/bin/llvm-as"
export LD="${ANDROID_NDK}/toolchains/llvm/prebuilt/linux-x86_64/bin/ld"
export LIPO="${ANDROID_NDK}/toolchains/llvm/prebuilt/linux-x86_64/bin/llvm-lipo"
export RANLIB="${ANDROID_NDK}/toolchains/llvm/prebuilt/linux-x86_64/bin/llvm-ranlib"
export OBJCOPY="${ANDROID_NDK}/toolchains/llvm/prebuilt/linux-x86_64/bin/llvm-objcopy"
export OBJDUMP="${ANDROID_NDK}/toolchains/llvm/prebuilt/linux-x86_64/bin/llvm-objdump"
export STRIP="${ANDROID_NDK}/toolchains/llvm/prebuilt/linux-x86_64/bin/llvm-strip"

export CFLAGS='-s -Os -w -Wfatal-errors -flto=full'
export CCFLAGS='-s -Os -w -Wfatal-errors -flto=full'
export CXXFLAGS='-s -Os -w -Wfatal-errors -flto=full'

cd './libressl'

make distclean

./configure --disable-tests \
	--disable-shared \
	--enable-static \
	--host='armv7a-linux-androideabi'

make --silent --jobs --directory=crypto
make --silent --jobs --directory=ssl

cd '../pcre'

make distclean

./configure --disable-cpp \
	--disable-shared \
	--enable-static \
	--host='armv7a-linux-androideabi'

make --silent --jobs

cd ..

nim compile \
	--os:'android' \
	--cpu:'arm' \
	--define:'release' \
	--define:'libressl' \
	--dynlibOverrideAll \
	--opt:'size' \
	--define:'useMalloc' \
	--define:'strip' \
	--define:'danger' \
	--panics:'on' \
	--gc:'orc' \
	--passC:'-flto=full' \
	--passL:"${LIBSSL}" \
	--passL:"${LIBCRYPTO}" \
	--passL:"${LIBPCRE}" \
	--clang.path:"$(dirname ${CC})" \
	--clang.exe:'armv7a-linux-androideabi21-clang' \
	--clang.linkerexe:'armv7a-linux-androideabi21-clang' \
	--out:"${CWD}/lib/android-arm/unalix" \
	'Unalix-nim/src/unalixpkg/main.nim'

"${STRIP}"  --discard-all --strip-all "${CWD}/lib/android-arm/unalix"

cd './libressl'
make distclean
cd '../pcre'
make distclean
cd ..

export CC="${ANDROID_NDK}/toolchains/llvm/prebuilt/linux-x86_64/bin/aarch64-linux-android21-clang"
export CXX="${ANDROID_NDK}/toolchains/llvm/prebuilt/linux-x86_64/bin/aarch64-linux-android21-clang++"

cd './libressl'

./configure --disable-tests \
	--disable-shared \
	--enable-static \
	--host='aarch64-linux-android'

make --silent --jobs --directory=crypto
make --silent --jobs --directory=ssl

cd '../pcre'

./configure --disable-cpp \
	--disable-shared \
	--enable-static \
	--host='aarch64-linux-android'

make --silent --jobs

cd ..

nim compile \
	--os:'android' \
	--cpu:'arm64' \
	--define:'release' \
	--define:'libressl' \
	--dynlibOverrideAll \
	--opt:'size' \
	--define:'useMalloc' \
	--define:'strip' \
	--define:'danger' \
	--panics:'on' \
	--gc:'orc' \
	--passC:'-flto=full' \
	--passL:"${LIBSSL}" \
	--passL:"${LIBCRYPTO}" \
	--passL:"${LIBPCRE}" \
	--clang.path:"$(dirname ${CC})" \
	--clang.exe:'aarch64-linux-android21-clang' \
	--clang.linkerexe:'aarch64-linux-android21-clang' \
	--out:"${CWD}/lib/android-arm64/unalix" \
	'Unalix-nim/src/unalixpkg/main.nim'

"${STRIP}"  --discard-all --strip-all "${CWD}/lib/android-arm64/unalix"

cd './libressl'
make distclean
cd '../pcre'
make distclean
cd ..

export CC="${ANDROID_NDK}/toolchains/llvm/prebuilt/linux-x86_64/bin/i686-linux-android21-clang"
export CXX="${ANDROID_NDK}/toolchains/llvm/prebuilt/linux-x86_64/bin/i686-linux-android21-clang++"

cd './libressl'

./configure --disable-tests \
	--disable-shared \
	--enable-static \
	--host='i686-linux-android'

make --silent --jobs --directory=crypto
make --silent --jobs --directory=ssl

cd '../pcre'

./configure --disable-cpp \
	--disable-shared \
	--enable-static \
	--host='i686-linux-android'

make --silent --jobs

cd ..

nim compile \
	--os:'android' \
	--cpu:'i386' \
	--define:'release' \
	--define:'libressl' \
	--dynlibOverrideAll \
	--opt:'size' \
	--define:'useMalloc' \
	--define:'strip' \
	--define:'danger' \
	--panics:'on' \
	--gc:'orc' \
	--passC:'-flto=full' \
	--passL:"${LIBSSL}" \
	--passL:"${LIBCRYPTO}" \
	--passL:"${LIBPCRE}" \
	--clang.path:"$(dirname ${CC})" \
	--clang.exe:'i686-linux-android21-clang' \
	--clang.linkerexe:'i686-linux-android21-clang' \
	--out:"${CWD}/lib/android-x86/unalix" \
	'Unalix-nim/src/unalixpkg/main.nim'

"${STRIP}"  --discard-all --strip-all "${CWD}/lib/android-x86/unalix"

cd './libressl'
make distclean
cd '../pcre'
make distclean
cd ..

export CC="${ANDROID_NDK}/toolchains/llvm/prebuilt/linux-x86_64/bin/x86_64-linux-android21-clang"
export CXX="${ANDROID_NDK}/toolchains/llvm/prebuilt/linux-x86_64/bin/x86_64-linux-android21-clang++"

cd './libressl'

./configure --disable-tests \
	--disable-shared \
	--enable-static \
	--host='x86_64-linux-android'

make --silent --jobs --directory=crypto
make --silent --jobs --directory=ssl

cd '../pcre'

./configure --disable-cpp \
	--disable-shared \
	--enable-static \
	--host='x86_64-linux-android'

make --silent --jobs

cd ..

nim compile \
	--os:'android' \
	--cpu:'amd64' \
	--define:'release' \
	--define:'libressl' \
	--dynlibOverrideAll \
	--opt:'size' \
	--define:'useMalloc' \
	--define:'strip' \
	--define:'danger' \
	--panics:'on' \
	--gc:'orc' \
	--passC:'-flto=full' \
	--passL:"${LIBSSL}" \
	--passL:"${LIBCRYPTO}" \
	--passL:"${LIBPCRE}" \
	--clang.path:"$(dirname ${CC})" \
	--clang.exe:'x86_64-linux-android21-clang' \
	--clang.linkerexe:'x86_64-linux-android21-clang' \
	--out:"${CWD}/lib/android-x86-64/unalix" \
	'Unalix-nim/src/unalixpkg/main.nim'

"${STRIP}"  --discard-all --strip-all "${CWD}/lib/android-x86-64/unalix"

rm -rf "${PWD}"