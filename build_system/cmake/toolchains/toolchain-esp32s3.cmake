################################################################################
# toolchain-esp32s3.cmake
#
# Author: [Himanshu Jangra]
# Date: [19-mar-2024]
#
# Description:
#   	toolchain file for esp32s3.
#
# Notes:
#       Please dont modify existing CMAKE function and commands unless highly required 
# 		 Additional notes
#
################################################################################
# [Contents of the file below]
# check for minimum cmake version to run this script
cmake_minimum_required(VERSION 3.2.1)


set(CMAKE_SYSTEM_NAME Generic)

set(CMAKE_C_COMPILER xtensa-esp32s3-elf-gcc)
set(CMAKE_CXX_COMPILER xtensa-esp32s3-elf-g++)
set(CMAKE_ASM_COMPILER xtensa-esp32s3-elf-gcc)
set(_CMAKE_TOOLCHAIN_PREFIX xtensa-esp32s3-elf-)



###################33 custom script to find the compiler path 
execute_process(
  COMMAND where ${CMAKE_C_COMPILER}
  OUTPUT_VARIABLE BINUTILS_PATH
  OUTPUT_STRIP_TRAILING_WHITESPACE
)

# find the compiler path by specifying the name of the compiler 
get_filename_component(Compiler_path "${BINUTILS_PATH}" DIRECTORY)


message(STATUS "the ${IDF_TARGET} compiler is ${Compiler_path}/${CMAKE_C_COMPILER}")

# specify the Executable suffix types
set(CMAKE_EXECUTABLE_SUFFIX_C     .o)
set(CMAKE_EXECUTABLE_SUFFIX_ASM   .o)
set(CMAKE_EXECUTABLE_SUFFIX_CXX   .o)
set(CMAKE_EXECUTABLE_SUFFIX .elf)

# build only the static library for the projects
set(BUILD_SHARED_LIBS OFF)

# cmake find_<types> inclusion of the certain paths in finding the <types> files 
set(CMAKE_FIND_ROOT_PATH ${Compiler_path})

set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
