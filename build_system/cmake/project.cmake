################################################################################
# project.cmake
#
# Author: [Himanshu Jangra]
# Date: [23-Feb-2024]
#
# Description:
#   	this is a project cmake file that will do the Basic initialisation and enviourment setup.
#
# Notes:
#       Please dont modify existing CMAKE function and commands unless highly required 
# 		 Additional notes
#
################################################################################
# [Contents of the file below]
# check for minimum cmake version to run this script
cmake_minimum_required(VERSION 3.2.1)

# append path for the cmake search path for other module files 
list(APPEND CMAKE_MODULE_PATH  
    ${CMAKE_CURRENT_LIST_DIR}/scripts 
    ${CMAKE_CURRENT_LIST_DIR}/toolchains 
    ${CMAKE_CURRENT_LIST_DIR}/tools
    ${CMAKE_CURRENT_LIST_DIR}
)

# include the build cmake file for building the basic build structure 
include(utility)
include(tools_setup)
include(build)
include(target)
# the above files doesn't requires sdkconfig.cmake file 


# the below files requires sdkconfig 
include(toolchain_file)

include(idf_support)
# =================================================================================================
# ======================== there are some TARGET  properties that needs to be included so rest of 
#  the cmakefiles will fetch for their use 

# cmake scripts paths ,
# Build component path,
# sdkconfig file, 
# sdkconfig defualt file
# targets 
# Default target
# 
# 
# __build_properties that hold all the properties defined by the rest cmakefiles 
# 

# @name __idf_dummy_target_init 
#   
# @note    used to init the dummy target for the build system
#           this targets hold all the build regarding properties and stuff   
# @usage   usage  
# @scope  scope   
# scope tells where should this cmake function used 
# 

function(__idf_dummy_target_init)
    # add a dummy target to store all the releavant information  regarding build
    add_library(__idf_build_target STATIC IMPORTED GLOBAL) 
endfunction()
    
# ==================================================================================================
# ==================================================================================================



# @name esp_sdk_init 
#   
# @note    used to initialise the sdk for the target    
# @usage   it is the first function to call when including this file 
# @scope  parent scope   
# scope tells where should this cmake function used 
# 
macro(esp_sdk_init )
    

    # check if build and source dir are set 
    if(NOT( DEFINED CMAKE_SOURCE_DIR AND  DEFINED CMAKE_BINARY_DIR))
        message(FATAL_ERROR "cmake source and binarry directory are not properly set")
    endif()

    # file(IS_DIRECTORY)
    if(NOT(EXISTS "${CMAKE_SOURCE_DIR}" AND EXISTS "${CMAKE_BINARY_DIR}"))
            message(FATAL_ERROR "cmake_source or binary directory doesn't exist")
    endif()
    
   
    # turn on the color diagnosistic feature 
    set(CMAKE_COLOR_DIAGNOSTICS ON)
    
    # set the new cmake policy 
    # cmake_policy(SET CMP0058 NEW) no beifits
    
    __idf_dummy_target_init()
    
    # setting the cmake scripts path into the TARGET property 
    idf_build_set_property(CMAKE_SCRIPTS_PATH  "D:\\stimveda_codebase\\V1_OTA\\cmake"  )
    idf_build_set_property(BUILD_COMPONENTS_PATH "D:\\stimveda_codebase\\V1_OTA\\components")
    idf_build_set_property(PROJECT_DIR  "${CMAKE_SOURCE_DIR}")
    
    # find the IDF path from the enviourment variables and set in the property 
    set(idf_path $ENV{IDF_PATH})
    if(NOT EXISTS ${idf_path})
        message(FATAL_ERROR "ESP-IDF path not set, please set the IDF path in ENV variables")
    endif()
    file(TO_CMAKE_PATH "${idf_path}" idf_path)
    # set the TARGET property for the IDF_PATH
    idf_build_set_property(IDF_PATH "${idf_path}")
    
    # find the sdkconfig file in the root project directory 
    __find_sdkconfig_file(sdkconfig_file)
    
    find_target_mcu(${sdkconfig_file} target)
    
    # initing the tools for the project 
    tools_init(${target})
    
    # init the enviourment for the target
    idf_init_process()

    # generate the sdkconfig file and include it in the build process 
    idf_generate_and_add_sdkconfig() 
    
    # include the toolchain file 
    toolchain_init(${target})
endmacro()



# @name  __find_sdkconfig_file
#   
# @param0  file_out 
# @note    used to find the sdkconfig file in the project directory 
# @usage   used in project init function 
# @scope  this file only
# scope tells where should this cmake function used 
# 
function(__find_sdkconfig_file file_out)

    # check if sdkconfig file is provided by the cmake args 
    if(SDKCONFIG)
        set(sdkconfig_file ${SDKCONFIG})
    else()
        # scan for sdkconfig file in the project source directory 
        find_file(sdkconfig_file "sdkconfig" HINTS "${CMAKE_SOURCE_DIR}/.." REQUIRED NO_CMAKE_FIND_ROOT_PATH)
        
        if(NOT sdkconfig_file)
            message(FATAL_ERROR "sdkconfig file doesn't exist in the \
                Project directory, make sure it is present in the top level of the project direcotry")
        endif()
    endif()

    message(STATUS "found sdkconfig file --> ${sdkconfig_file}")
    
    set(${file_out} "${sdkconfig_file}" PARENT_SCOPE) 
    
    # also set the property
    idf_build_set_property(SDKCONFIG  "${sdkconfig_file}") 

    idf_build_set_property(SDKCONFIG_DEFAULT "")

endfunction()
