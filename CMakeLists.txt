cmake_minimum_required(VERSION 3.27 FATAL_ERROR) #? 3.27 - SKIP_LINTING

#==========  Project Details  ==================================================#

project(ctcache VERSION 1.0)

#============  Safe Guards  ====================================================#

include(cmake/SafeGuards.cmake)
variable_watch(CMAKE_BUILD_TYPE readonly_guard)

#==========  CMake Variables  ==================================================#

if(NOT DEFINED CMAKE_CXX_STANDARD)
    set(CMAKE_CXX_STANDARD
        20
        CACHE STRING "The C++ standard to use."
    )
endif()

set(CMAKE_CXX_STANDARD_REQUIRED 17)

set(CMAKE_CXX_EXTENSIONS OFF)
set(CMAKE_C_EXTENSIONS OFF)

set(CMAKE_SUPPRESS_REGENERATION ON)

set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

#=======  Manual File Additions  ===============================================#

set(SKIP_LINTING_LIST # List of files to exclude from clang-tidy static analysis
    "${CMAKE_CURRENT_SOURCE_DIR}/src/ClangTidyWarnings.cpp" "${CMAKE_CURRENT_SOURCE_DIR}/include/ClangTidyWarnings.h"
)

set(PRECOMPILED_HEADER_LIST # List of files to be precompiled
    "${CMAKE_CURRENT_SOURCE_DIR}/include/pch.h"
)

#====  Define CMake Module Imports  ============================================#

include(CMakeParseArguments)

option(ENABLE_WARNINGS "Enable to add compiler warnings." ON)
option(ENABLE_WARNINGS_AS_ERRORS "Enable to treat compiler warnings as errors." OFF)

include(cmake/Cache.cmake)
enable_cache()

include(cmake/StaticAnalyzers.cmake)
enable_clang_tidy()

include(cmake/InterproceduralOptimization.cmake)
enable_ipo()

include(cmake/Warnings.cmake)

#=========  Compiler/OS Fixes  =================================================#

# Enhance error reporting and compiler messages
if(CMAKE_CXX_COMPILER_ID MATCHES ".*Clang")
    if(WIN32)
        # On Windows cuda nvcc uses cl and not clang
        add_compile_options($<$<COMPILE_LANGUAGE:C>:-fcolor-diagnostics> $<$<COMPILE_LANGUAGE:CXX>:-fcolor-diagnostics>)
    else()
        add_compile_options(-fcolor-diagnostics)
    endif()

    set(WINDOWS_HEADERS_NEEDED_BY_CLANG_LIST "$ENV{EXTERNAL_INCLUDE}")
elseif(CMAKE_CXX_COMPILER_ID STREQUAL "GNU")
    if(WIN32)
        # On Windows cuda nvcc uses cl and not gcc
        add_compile_options($<$<COMPILE_LANGUAGE:C>:-fdiagnostics-color=always> $<$<COMPILE_LANGUAGE:CXX>:-fdiagnostics-color=always>)
    else()
        add_compile_options(-fdiagnostics-color=always)
    endif()
elseif(CMAKE_CXX_COMPILER_ID STREQUAL "MSVC")
    if(MSVC_VERSION GREATER 1900)
        add_compile_options(/diagnostics:column)
    endif()

    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} /EHsc") # Microsoft’s compiler is super old and they care a lot about backwards compatibility so this needs to be added manually
else()
    message(STATUS "No colored compiler diagnostic set for '${CMAKE_CXX_COMPILER_ID}' compiler.")
endif()

#========== Add Source Files ==================================================#

foreach(SOURCE_FILE IN LISTS SKIP_LINTING_LIST)
    set_source_files_properties(${SOURCE_FILE} PROPERTIES SKIP_LINTING ON)
endforeach()

#===========  Create Target  ===================================================#

add_executable(${PROJECT_NAME} src/Main.cpp)
target_sources(${PROJECT_NAME} PRIVATE src/ClangTidyWarnings.cpp)

target_include_directories(${PROJECT_NAME} PRIVATE "${WINDOWS_HEADERS_NEEDED_BY_CLANG_LIST}" "${PROJECT_SOURCE_DIR}/include")

target_precompile_headers(${PROJECT_NAME} PRIVATE "$<$<COMPILE_LANGUAGE:CXX>:${PRECOMPILED_HEADER_LIST}>")

#=====  Set Standard and Warnings  =============================================#

set_target_properties(
    ${PROJECT_NAME}
    PROPERTIES CXX_STANDARD ${CMAKE_CXX_STANDARD}
               CXX_STANDARD_REQUIRED 17
               CXX_EXTENSIONS NO
               RUNTIME_OUTPUT_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/bin"
               LIBRARY_OUTPUT_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/lib"
               ARCHIVE_OUTPUT_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/lib"
)

target_set_warnings(${PROJECT_NAME})
