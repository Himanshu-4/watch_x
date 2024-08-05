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

cmake_policy(SET CMP0057 NEW)

set(CMAKE_CURENT_DIRECTORY "${CMAKE_CURRENT_LIST_DIR}")

# append path for the cmake search path for other module files 
list(APPEND CMAKE_MODULE_PATH  
    ${CMAKE_CURRENT_LIST_DIR}/scripts 
    ${CMAKE_CURRENT_LIST_DIR}/toolchains 
    ${CMAKE_CURRENT_LIST_DIR}/tools
    ${CMAKE_CURRENT_LIST_DIR}
)


include(utility)
include(ldgen)
include(build)
include(target) # target automatically add the toolchain 
include(components)


# ==================================================================================================
# ==================================================================================================


# @name __Execute the config_python_script  
#   
# @param0  config_file
# @param1  out_file
# @note    used to execute python for config file
# @usage   usage  
# @scope  in a macro defined below
# scope tells where should this cmake function used 
# 
function(__execute_config_python_script config_file out_file)
    
    if(NOT EXISTS ${config_file})
        message(FATAL_ERROR "the ${config_file} doesn;t exist in path")
    endif()
    # set the python script as parse_config.py 
    set(PYTHON_SCRIPT "${CMAKE_CURENT_DIRECTORY}/../python_scripts/parse_config.py")
    
    # execute the process , edit should be done at the root level (project dir)
    execute_process(
                COMMAND ${CMAKE_COMMAND} -E env python ${PYTHON_SCRIPT} ${config_file} ${out_file}
                WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
                RESULT_VARIABLE result
                OUTPUT_VARIABLE output
                ERROR_VARIABLE error
                    )

    # Check if the Python script ran successfully
    if(result EQUAL 0)
        message(STATUS "Generated ${out_file} for Cmake form ${config_file}")
        message(STATUS "Output: ${output}")
    else()
        message(FATAL_ERROR "Python script failed with error: ${error}")
    endif()
        
endfunction()


# @name project_gen_conf_file
#   
# @param0  "project_config.conf" 
# @note    used to add the config file to the build 
# @usage   this can be used to initiate the configuration 
# @scope  root cmake file
# scope tells where should this cmake function used 
#
macro(project_gen_conf_file config_file config_dir)
    
    # find the file, the project config file can be found only in 
    # project root  directory , root level cmakefile, or where src is defined 
    find_file(config_out ${config_file}  
                PATHS ${CMAKE_SOURCE_DIR}
                REQUIRED 
                NO_DEFAULT_PATH)
    
    if (NOT EXISTS ${config_dir})
        message(FATAL_ERROR "the ${config_dir} doesn't exist")
    endif()

    set(include_file "${config_dir}/project_config.cmake")
    __execute_config_python_script("${config_out}" "${include_file}")

    # include that cmake file
    include(${include_file})
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

    # set the paths and check it  
    foreach(path ${PATH})
        if (NOT EXISTS ${path})
            message(FATAL_ERROR "one of the path ${path} supplied is not exists")
        endif()
    endforeach()
    
    if(NOT( DEFINED CMAKE_SOURCE_DIR AND  DEFINED CMAKE_BINARY_DIR))
        # set the directoreis 
        set(CMAKE_SOURCE_DIR "${PATH_SRC_DIR}")
        set(CMAKE_BINARY_DIR "${PATH_BUILD_DIR}")
    endif()
    
    # set the path vraibles 
    idf_build_set_property(IDF_PATH "${PATH_IDF_PATH}")
    idf_build_set_property(IDF_TOOLS "${PATH_IDF_TOOLS}")
    idf_build_set_property(PROJECT_DIR  "${CMAKE_SOURCE_DIR}")
   
    # turn on the color diagnosistic feature 
    set(CMAKE_COLOR_DIAGNOSTICS ON)
     
    __idf_dummy_target_init()
    
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
