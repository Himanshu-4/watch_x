################################################################################
# Cmakelists.txt
#
# Author: [Himanshu Jangra]
# Date: [23-Feb-2024]
#
# Description:
#   	Root level cmake file , this file is used for root level 
#       PROJECT config and building .
#
# Notes:
#       Please dont modify existing CMAKE function and commands unless highly required 
# 		 Additional notes
#
################################################################################
# [Contents of the file below]
# check for minimum cmake version to run this script
cmake_minimum_required(VERSION 3.2.1)


# -------------------------------------------------------------------------------------
# ------------------- include the root level cmake file --------------------------------
include(build_system/cmake/project.cmake)

# -------------------------------------------------------------------------------
# read the root level configuration file, set the cache varaible that are defined in the config file
project_gen_conf_file("project_config.conf"  "${CMAKE_CURRENT_LIST_DIR}/src/configs")

project_init()

message(STATUS "COMPOENETS are --> ${BUILD_COMPONENTS}")

# from the kconfig generator, build a rough estimation of the project by including the components dir 
# and their kconfig file for project configurations 
# project_include_components(${BUILD_COMPONENTS})


# create a project 
project(${NAME} VERSION "1.0.0")



set(kernel_target watch_x_kernel)
# create a build file for the project (this is target that has a direct dependency with upload )
# project_add_executable(${kernel_target}  kerenel SOURCE_DIR ./src/kernel)

# create library files or define the library targets aka spi, newlib --> based on the component name 

# project_add_libraries(${BUILD_COMPONENTS})

# generate the library target based on the library list  defined earlier 

# now at this point you have all the library files that need to be used in the project 

# include the subfolder for building any lib or any lib that depends on the above library 

# link the library with the build target , above library list is passed here
# project_link_libraries(${kernel_target})

# create size targets, executable target  for the above build target 
# project_build_executable(${kernel_target})

# create the flash target for the above build target 
# project_add_flash_target()

# /------------============================---------------------------------===============================--------
# =============------------------=========== same way you can create other targets ==================-----------

