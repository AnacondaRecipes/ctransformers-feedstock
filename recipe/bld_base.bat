:: cmd
@echo on

echo "Building %PKG_NAME%."

SetLocal EnableDelayedExpansion

if "%ctransformers_variant%"=="cpu" (
	set CT_CUBLAS="-DCT_CUBLAS=OFF"
) else (
	set CT_CUBLAS="-DCT_CUBLAS=ON"
)

REM Notes:
REM * win-64 and linux-64 supports CT_INSTRUCTIONS=avx and CT_INSTRUCTIONS=avx2. It's up to us to decide which one we want to support.
REM * avx2 is a default supported instruction.
:: TODO: add support for all supported instructions
cmake . -G Ninja -B build -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=ON %CT_CUBLAS%
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
