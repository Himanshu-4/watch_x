################################################################################
# project.cmake
#
# Author: [Himanshu Jangra]
# Date: [23-Feb-2024]
#
# Description:
#   	this is a project cmake file that will do the Basic initialisation and enviourment setup.
#       its methods depednds on other cmake module for project building 
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
include(tool_setup)

include(build)

# include the project configuration file
include(project_conf)


# ==================================================================================================
# ==================================================================================================

# @name project_init
#   
# @param0  param0 
# @param1  param1 
# @note    Note   
# @usage   usage  
# @scope  global   
# scope tells where should this cmake function used 
# 
macro(project_init )
    # init the project 

endmacro()


# @name project_read_conf_file
#   
# @param0  "project_config.conf" 
# @note    used to add the config file to the build 
# @usage   this can be used to initiate the configuration 
# @scope  root cmake file
# scope tells where should this cmake function used 
# 
macro(project_read_conf_file config_file)
    # find the file 
    find_file(config_out ${config_file}  
                PATHS ${CMAKE_CURRENT_LIST_DIR}
                REQUIRED 
                NO_DEFAULT_PATH)

    message(STATUS "reading the file ${config_out}")
    
    # read the file and decode it 
    __read_conf_file(${config_out})

    # see which configuration goes where 

    # read the file configuration 

    # generate the variables that will be used afterwards

    # all vars must be cache 
endmacro()


# @name project_include_sdkconfig  
# @param0  sdkconfig
# @note    this includes the sdkconfig file to the project 
# @usage   used to generate the sdkconfig file and 
# @scope  root cmake file   
# scope tells where should this cmake function used 
# 
macro(project_include_sdkconfig_file sdkconfig)
    # generate the kconfig files and include in the cmake build
endmacro()


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
