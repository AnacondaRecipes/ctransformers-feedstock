:: cmd
@echo on

echo "Building %PKG_NAME%."

SetLocal EnableDelayedExpansion

if "%gpu_variant%"=="cpu" (
	set CMAKE_ARGS="-DCT_CUBLAS=OFF"
) else (
	set CMAKE_ARGS="-DCT_CUBLAS=ON"
)


REM relevant section: https://github.com/marella/ctransformers/blob/v0.2.27/CMakeLists.txt#L68-L98
if "%x86_64_opt%"=="v3" (
	set CMAKE_ARGS="%CMAKE_ARGS% -DCT_INSTRUCTIONS=avx2"
) else if "%x86_64_opt%"=="v2" (
	set CMAKE_ARGS="%CMAKE_ARGS% -DCT_INSTRUCTIONS=avx"
) else (
    set CMAKE_ARGS="%CMAKE_ARGS% -DCT_INSTRUCTIONS=basic"
)

cmake . -G Ninja -B build -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=ON %CMAKE_ARGS%
if %ERRORLEVEL% neq 0 exit 1

cmake --build build --parallel %CPU_COUNT% --verbose
if %ERRORLEVEL% neq 0 exit 1

:: Without %PREFIX% it will be installed incorrectly into C:\Program files\lib
cmake --install build --prefix %PREFIX%
if %ERRORLEVEL% neq 0 exit 1

REM The repo contains pre-compiled libraries. We don't want that.
rmdir /s /q ctransformers\lib

set "CT_WHEEL=1"
%PYTHON% -m pip install . -v --no-deps --no-build-isolation
