@echo off
setlocal enabledelayedexpansion

:: Check if CTCACHE_CLANG_TIDY environment variable exists
if not defined CTCACHE_CLANG_TIDY (
    set "CTCACHE_CLANG_TIDY=C:\Program Files\LLVM\bin\clang-tidy.exe"
)

:: Define the path to ctcache-clang-tidy
set "CTCACHE_CLANG_CACHE=%~dp0..\clang-tidy-cache"

python !CTCACHE_CLANG_CACHE! !CTCACHE_CLANG_TIDY! %*

endlocal
