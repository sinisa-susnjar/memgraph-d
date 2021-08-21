@ECHO OFF
IF "%PACKAGE_DIR%"=="" set PACKAGE_DIR=%~dp0
@REM git submodule update --init --recursive
mkdir %PACKAGE_DIR%\mgclient\build
cd %PACKAGE_DIR%\mgclient\build
cmake ..
cmake --build .
