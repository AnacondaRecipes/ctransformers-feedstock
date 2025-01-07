:: cmd
@echo on

echo "Building %PKG_NAME%."

SetLocal EnableDelayedExpansion

if "%ctransformers_variant%"=="cpu" (
    set "GPU_SUPPORT=OFF"
	set CMAKE_ARGS="%CMAKE_ARGS% -DCT_CUBLAS=%GPU_SUPPORT%"
) else (
    set "GPU_SUPPORT=ON"
	set CMAKE_ARGS="%CMAKE_ARGS% -DCT_CUBLAS=%GPU_SUPPORT%"
)

REM Notes:
REM * win-64 and linux-64 supports CT_INSTRUCTIONS=avx and CT_INSTRUCTIONS=avx2. It's up to us to decide
REM   which one we want to support.
cmake . -G Ninja -B build -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=ON %CMAKE_ARGS%
if %ERRORLEVEL% neq 0 exit 1

cmake --build build --parallel %CPU_COUNT% --verbose
if %ERRORLEVEL% neq 0 exit 1

cmake --install build --prefix %PREFIX%
if %ERRORLEVEL% neq 0 exit 1

REM The repo contains pre-compiled libraries. We don't want that.
rmdir /s /q ctransformers\lib

set "CT_WHEEL=1"
%PYTHON% -m pip install . -v --no-deps --no-build-isolation
