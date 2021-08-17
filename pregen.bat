@ECHO OFF
IF "%PACKAGE_DIR%"=="" set PACKAGE_DIR=%~dp0
git submodule update --init --recursive
mkdir %PACKAGE_DIR%\mgclient\build
cd %PACKAGE_DIR%\mgclient\build
cmake .. -G "MinGW Makefiles"
cmake --build .
