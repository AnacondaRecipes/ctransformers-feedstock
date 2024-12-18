#!/usr/bin/env bash
set -ex

export GPU_SUPPORT="ON"
if [[ ${ctransformers_variant} == "cpu" ]]; then
    export GPU_SUPPORT="OFF"
fi

if [[ ${target_platform} == osx-* ]]; then
    export CMAKE_ARGS="${CMAKE_ARGS} -DCT_METAL=${GPU_SUPPORT}"
else
    export CMAKE_ARGS="${CMAKE_ARGS} -DCT_CUBLAS=${GPU_SUPPORT}"
fi

if [[ ${target_platform} == linux-* ]]; then
    # Provided in docker image
    export CUDACXX=/usr/local/cuda/bin/nvcc
    # If this isn't included, CUDA will use the system compiler to compile host
    export CUDAHOSTCXX="${CXX}"
    if [[ "$target_platform" == "linux-64" ]]; then
        # See also https://github.com/marella/ctransformers/issues/120#issuecomment-1699906392
        export CMAKE_ARGS="${CMAKE_ARGS} -DCT_INSTRUCTIONS=avx -DCT_CUBLAS=${GPU_SUPPORT}"
    fi
fi

# Notes:
# * osx-arm64 and linux-aarch64 will also default to CT_INSTRUCTIONS=basic (-mcpu=native)
# * win-64 and linux-64 supports CT_INSTRUCTIONS=avx and CT_INSTRUCTIONS=avx2. It's up to us to decide
#   which one we want to support.
cmake . -G Ninja -B build -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=ON ${CMAKE_ARGS}

cmake --build build --parallel ${CPU_COUNT} --verbose
cmake --install build

# The repo contains pre-compiled libraries. We don't want that.
rm -v -rf ctransformers/lib

CT_WHEEL=1 python -m pip install . -v --no-deps --no-build-isolation
