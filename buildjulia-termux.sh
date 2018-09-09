#!/data/data/com.termux/files/usr/bin/sh
export BIT64_SYSTEM_LIBS=1
export LD_LIBRARY_PATH=$PWD/usr/lib:$LD_LIBRARY_PATH
export PATH=$PREFIX/opt/julia-llvm/bin:$PATH
setupclang-gfort-8
cp Make.user-termux Make.user
export LDFLAGS="-L$PREFIX/opt/julia-llvm/lib -L$PWD/usr/lib -L$PREFIX/lib -lm -lcompiler_rtjulia -landroid-support -lopenblas -lbthread  -lgfortran -latomic"
echo "JULIA for android..."
echo "THIS NEEDS suitesparse-dev patch tar libgfortran5 openblas arpack-ng libssh2-dev libcurl-dev patchelf libgmp-dev pcre2-dev bthread-dev libclang-dev libllvm-dev libgit2-dev\n julia-llvm libcompiler-rtjulia"
echo "arm and aarch64 need gcc-8"
echo "only arm needs libunwind-dev"
TERMUX_ARCH=$(dpkg --print-architecture)
cd base
sh $PWD/version_git.sh $PWD > version_git.jl.phony
cd ../
cd src
make julia_version.h
cd ../

if [ $TERMUX_ARCH = "arm" ]; then
echo "USE_SYSTEM_LIBUNWIND:=1" >> Make.user
echo "DISABLE_LIBUNWIND:=0" >> Make.user
export BIT64_SYSTEM_LIBS=0
export JULIA_CPU_TARGET=armv7-a
make julia-deps
# for arm compiling src/support/hashing.c with clang creates bus errors so need to use gcc-8
gcc-8 -fasynchronous-unwind-tables -DSYSTEM_LLVM -DJULIA_ENABLE_THREADING -DJULIA_NUM_THREADS=3 -DJL_DISABLE_LIBUNWIND -std=gnu99 -pipe -fPIC -fno-strict-aliasing -D_FILE_OFFSET_BITS=64 -fsigned-char -Wold-style-definition -Wstrict-prototypes -Wc++-compat -O3 -ggdb2 -falign-functions  -I$PWD/usr/include -DLIBRARY_EXPORTS -DUTF8PROC_EXPORTS -Wall -Wno-strict-aliasing -fvisibility=hidden -Wpointer-arith -Wundef -DNDEBUG -DJL_NDEBUG -c src/support/hashing.c -o src/support/hashing.o
#inline assembly fails...
gcc-8 -fasynchronous-unwind-tables -DSYSTEM_LIBUNWIND -DSYSTEM_LLVM -DJULIA_HAS_IFUNC_SUPPORT=1 -DJULIA_ENABLE_THREADING -DJULIA_NUM_THREADS=3 -std=gnu99 -pipe -fPIC -fno-strict-aliasing -D_FILE_OFFSET_BITS=64 -fsigned-char -DSYSTEM_LIBUNWIND -Wold-style-definition -Wstrict-prototypes -Wc++-compat -O3 -ggdb2 -falign-functions -D_GNU_SOURCE -I. -I$PWD/src -I$PWD/src/flisp -I$PWD/src/support -I$PWD/usr/include -I$PWD/usr/include -DLIBRARY_EXPORTS -I$PWD/deps/valgrind -Wall -Wno-strict-aliasing -fno-omit-frame-pointer -fvisibility=hidden -fno-common -Wpointer-arith -Wundef -DJL_BUILD_ARCH='"arm"' -DJL_BUILD_UNAME='"Linux"' -I/data/data/com.termux/files/usr/include -DLLVM_SHLIB "-DJL_SYSTEM_IMAGE_PATH=\"../lib/julia/sys.so\"" -DNDEBUG -DJL_NDEBUG -c src/interpreter.c -o src/interpreter.o
elif [ $TERMUX_ARCH = "aarch64" ]; then
# compiling fails using clang for these files so use gcc-8
export JULIA_CPU_TARGET="cortex-a53"
export BIT64_SYSTEM_LIBS=1

make julia-deps -j 4
gcc-8 -fasynchronous-unwind-tables -DSYSTEM_LLVM -DJULIA_HAS_IFUNC_SUPPORT=1 -DJULIA_ENABLE_THREADING -DJULIA_NUM_THREADS=3 -DJL_DISABLE_LIBUNWIND -std=gnu99 -pipe -fPIC -fno-strict-aliasing -D_FILE_OFFSET_BITS=64 -Wold-style-definition -Wstrict-prototypes -Wc++-compat -O3 -ggdb2 -falign-functions -D_GNU_SOURCE -I. -I$PWD/src -I$PWD/src/flisp -I$PWD/src/support -I$PWD/usr/include -DLIBRARY_EXPORTS -I$PWD/deps/valgrind -Wall -Wno-strict-aliasing -fno-omit-frame-pointer -fvisibility=hidden -fno-common -Wpointer-arith -Wundef -DJL_BUILD_ARCH='"aarch64"' -DJL_BUILD_UNAME='"Linux"' -I/data/data/com.termux/files/usr/include -DLLVM_SHLIB "-DJL_SYSTEM_IMAGE_PATH=\"../lib/julia/sys.so\"" -DNDEBUG -DJL_NDEBUG  -c src/task.c -o src/task.o
gcc-8 -fasynchronous-unwind-tables -DSYSTEM_LLVM -DJULIA_HAS_IFUNC_SUPPORT=1 -DJULIA_ENABLE_THREADING -DJULIA_NUM_THREADS=3 -DJL_DISABLE_LIBUNWIND -std=gnu99 -pipe -fPIC -fno-strict-aliasing -D_FILE_OFFSET_BITS=64 -Wold-style-definition -Wstrict-prototypes -Wc++-compat -O3 -ggdb2 -falign-functions -D_GNU_SOURCE -I. -I$PWD/src -I$PWD/src/flisp -I$PWD/src/support -I$PWD/usr/include -DLIBRARY_EXPORTS -I$PWD/deps/valgrind -Wall -Wno-strict-aliasing -fno-omit-frame-pointer -fvisibility=hidden -fno-common -Wpointer-arith -Wundef -DJL_BUILD_ARCH='"aarch64"' -DJL_BUILD_UNAME='"Linux"' -I/data/data/com.termux/files/usr/include -DLLVM_SHLIB "-DJL_SYSTEM_IMAGE_PATH=\"../lib/julia/sys.so\"" -DNDEBUG -DJL_NDEBUG  -c src/crc32c.c -o src/crc32c.o
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

