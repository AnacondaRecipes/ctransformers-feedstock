#!/usr/bin/env bash
set -ex

# The repo contains pre-compiled libraries. We don't want that.
rm -v -rf ctransformers/lib

if [[ ${gpu_variant} != "none" ]]; then
    if [[ ${target_platform} == osx-* ]]; then
        export CMAKE_ARGS="${CMAKE_ARGS} -DCT_METAL=ON"
    else
        export CMAKE_ARGS="${CMAKE_ARGS} -DCT_CUBLAS=ON"
    fi
fi

# Configure CPU optimization flags based on the x86_64_opt variable:
# - "v3" sets march=x86-64-v3, enabling AVX, AVX2, and other extensions (suitable for modern CPUs)
# - Any other value (or unset) keeps the default march=nocona (for older CPUs or maximum compatibility)
# This affects CXXFLAGS, CFLAGS, and CPPFLAGS to ensure consistent optimization across all compilations.
# relevant section: https://github.com/marella/ctransformers/blob/v0.2.27/CMakeLists.txt#L68-L98
export CMAKE_ARGS="${CMAKE_ARGS} -DCT_INSTRUCTIONS=basic"
if [[ ${x86_64_opt:-} != "none" ]]; then
    if [[ ! "${CXXFLAGS}" =~ "march=nocona" ]]; then
        echo "Error: Substring 'march=nocona' not found in CXXFLAGS - gcc activation scripts have changed." >&2
        exit 1
    fi
    export CXXFLAGS="${CXXFLAGS/march=nocona/march=x86-64-${x86_64_opt}}"
    export CFLAGS="${CFLAGS/march=nocona/march=x86-64-${x86_64_opt}}"
    export CPPFLAGS="${CPPFLAGS/march=nocona/march=x86-64-${x86_64_opt}}"
fi

cmake . -G Ninja -B build -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=ON ${CMAKE_ARGS}

cmake --build build --parallel ${CPU_COUNT} --verbose
cmake --install build --prefix "${PREFIX}"

CT_WHEEL=1 ${PYTHON} -m pip install . -v --no-deps --no-build-isolation
