#!/data/data/com.termux/files/usr/bin/sh
export BIT64_SYSTEM_LIBS=1
export LD_LIBRARY_PATH=$PWD/usr/lib
export PATH=$PREFIX/opt/julia-llvm/bin:$PATH
setupclang-gfort-9
cp Make.user-termux Make.user
export LDFLAGS="-L$PREFIX/opt/julia-llvm/lib -L$PWD/usr/lib -L$PREFIX/lib -lm -lcompiler_rt-termux -landroid-support -lopenblas -lbthread  -lgfortran -latomic"
echo "JULIA for android..."
echo "THIS NEEDS suitesparse-dev patch tar libgfortran5 openblas arpack-ng libssh2-dev libcurl-dev patchelf libgmp-dev pcre2-dev bthread-dev libclang-dev libllvm-dev libgit2-dev\n julia-llvm libcompiler-rt-termux"
echo "arm and aarch64 need gcc-8"
TERMUX_ARCH=$(dpkg --print-architecture)
cd base
sh $PWD/version_git.sh $PWD > version_git.jl.phony
cd ../
cd src
make julia_version.h
cd ../

if [ $TERMUX_ARCH = "arm" ]; then
export BIT64_SYSTEM_LIBS=0
export JULIA_CPU_TARGET=armv7-a
export CFLAGS="-march=armv7-a -mfpu=neon -mfloat-abi=softfp -mthumb"
export CXXFLAGS="-march=armv7-a -mfpu=neon -mfloat-abi=softfp -mthumb"
make julia-deps -j 3

elif [ $TERMUX_ARCH = "aarch64" ]; then
# compiling fails using clang for these files so use gcc-8
export JULIA_CPU_TARGET="cortex-a53"
export BIT64_SYSTEM_LIBS=1
export CFLAGS="-march=armv8-a+crc"
make julia-deps -j 4
else
    export JULIA_CPU_TARGET=atom 
   dpkg --print-architecture | grep 64 || export BIT64_SYSTEM_LIBS=0
    make julia-deps -j 4

fi

make julia_flisp.boot.inc.phony
make termux -j 4 BIT64_SYSTEM_LIBS=$BIT64_SYSTEM_LIBS
make install
strip $PREFIX/opt/julia/bin/julia
strip $PREFIX/opt/julia/lib/libjulia.so 
termux-elf-cleaner $PREFIX/opt/julia/bin/julia
termux-elf-cleaner $PREFIX/opt/julia/lib/libjulia.so
cp usr/lib/libuv.a $PREFIX/opt/julia/lib

