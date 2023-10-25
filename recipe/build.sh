#!/usr/bin/env bash
set -ex

if [[ ${target_platform} == osx-* ]]; then
    export CMAKE_ARGS="${CMAKE_ARGS} -DCT_METAL=ON"
else
    export CMAKE_ARGS="${CMAKE_ARGS} -DCT_CUBLAS=ON"
fi

if [[ ${target_platform} == linux-* ]]; then
    # Provided in docker image
    export CUDACXX=/usr/local/cuda/bin/nvcc
    # If this isn't included, CUDA will use the system compiler to compile host
    export CUDAHOSTCXX="${CXX}"
fi

# Notes:
# * osx-arm64 and linux-aarch64 will also default to CT_INSTRUCTIONS=basic (-mcpu=native)
# * win-64 and linux-64 supports CT_INSTRUCTIONS=avx and CT_INSTRUCTIONS=avx2. It's up to us tp decide
#   which one we want to support.
# * On osx, should we always enable metal? (-DCT_METAL=ON)...  THIS IS GPU! https://github.com/marella/ctransformers/blob/v0.2.27/ctransformers/lib.py#L18
cmake . -B build_ -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=ON ${CMAKE_ARGS}

VERBOSE=1 cmake --build build_
cmake --install build_

# The repo contains pre-compiled libraries. We don't want that.
rm -v -rf ctransformers/lib

CT_WHEEL=1 python -m pip install . -v --no-deps --no-build-isolation
