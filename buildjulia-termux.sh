#!/data/data/com.termux/files/usr/bin/sh
export LD_LIBRARY_PATH=$PWD/usr/lib:$LD_LIBRARY_PATH
cp Make.user-termux Make.user
export LDFLAGS="-L$PWD/usr/lib -L$PREFIX/lib -lm -lcompiler_rt -landroid-support -lopenblas -lbthread  -lgfortran -latomic"
echo "JULIA for android..."
echo "THIS NEEDS suitesparse-dev libgfortran4 openblas arpack-ng libssh2-dev libcurl-dev patchelf libgmp-dev pcre2-dev"

make termux

