################################################################################
# target.cmake
#
# Author: [Himanshu Jangra]
# Date: [23-Feb-2024]
#
# Description:
#   	Find the specific target into the build and from that include the specific toolchains 
#
# Notes:
#       Please dont modify existing CMAKE function and commands unless highly required 
# 		 Additional notes
#
################################################################################
# [Contents of the file below]
# check for minimum cmake version to run this script
cmake_minimum_required(VERSION 3.2.1)


# @name __target_from_config 
#           
# @param0  config_file 
# @param1  target_out 
# @note    this is to find the target in the sdkconfig_file
# @usage   used in target init to find the target 
# @scope  only this file   
# scope tells where should this cmake function used 
# 
function(__target_from_config config_file target_out)
    
    set(${target_out} "" PARENT_SCOPE)

    # please specify the full path of the config file
    if(NOT EXISTS "${config_file}")
        message(WARNING "Can't find the ${config_file} for finding the target mcu")
        return()
    endif()

    file(STRINGS "${config_file}" lines)
    foreach(line ${lines})
        if(NOT "${line}" MATCHES "^CONFIG_IDF_TARGET=\"[^\"]+\"$")
            continue()
        endif()

        string(REGEX REPLACE "CONFIG_IDF_TARGET=\"([^\"]+)\"" "\\1" target "${line}")
        set(${target_out} ${target} PARENT_SCOPE)
        return()
    endforeach()
endfunction()

# @name __target_from_configs 
#   
# @param0  config 
# @param1  target_out  
# @param2 file_out 
# @usage   usage    
# @scope  scope   
# scope tells where should this cmake function used 
# 
function(__target_from_configs configs target_out file_out)
    set(file "")
    foreach(config ${configs})
        message(STATUS "Searching for target in '${config}'")
        get_filename_component(config "${config}" ABSOLUTE)
        __target_from_config("${config}" target)
        # if found target then break the loop
        if(target)
            set(file ${config})
            break()
        endif()
    endforeach()

    # send out the return variables
    set(${target_out} "${target}" PARENT_SCOPE)
    set(${file_out} "${file}" PARENT_SCOPE)
endfunction()

# @name __target_guess 
#   
# @param0  target_out 
# @param1  file_out 
# @param2  sdkconfig_file
# @note    guess the target from the sdkconfig file and if found give back the 
#           sdkconfig file and thje target  
# @usage   used in find_target_mcu
# @scope  parent_scope
# scope tells where should this cmake function used 
# 
function(__target_guess sdkconfig_file target_out file_out)
    # Select sdkconfig_defaults to look for target
    if(SDKCONFIG_DEFAULTS)
        set(defaults "${SDKCONFIG_DEFAULTS}")
    elseif(DEFINED ENV{SDKCONFIG_DEFAULTS})
        set(defaults "$ENV{SDKCONFIG_DEFAULTS}")
    endif()

    if(NOT defaults)
        set(defaults "${CMAKE_SOURCE_DIR}/sdkconfig.defaults")
    endif()

    set(configs "${sdkconfig_file}" "${SDKCONFIG}" "${defaults}")
    # message(STATUS "Searching for target in '${configs}'")
    __target_from_configs("${configs}" target file)
    set(${target_out} "${target}" PARENT_SCOPE)
    set(${file_out} "${file}" PARENT_SCOPE)
endfunction()

# @name find_target_mcu 
#   
# @param0  sdkconfig_file   
# @param1  target
# @note    used to find the target mcu from the sdkconfig file 
#          or to guess from the other variables  
# @usage   to find the target mcu
# @scope  main_project file
# scope tells where should this cmake function used 
# 
function(find_target_mcu sdkconf_file target)
        
    # Input is IDF_TARGET environement variable
    set(env_idf_target $ENV{IDF_TARGET})
    
    if(NOT env_idf_target)
        # IDF_TARGET not set in environment, see if it is set in cache
        if(DEFINED CACHE{IDF_TARGET})
            set(env_idf_target ${IDF_TARGET})
        
        elseif(IDF_TARGET)
            message(STATUS "IDF target is defined in the cmaek argument ${IDF_TARGET}")
            set(env_idf_target ${IDF_TARGET})
        else()
            
            # Try to guess IDF_TARGET from sdkconfig files while honoring
            # SDKCONFIG and SDKCONFIG_DEFAULTS values
            __target_guess(${sdkconf_file} env_idf_target conf_file)
            if(env_idf_target)
                message(STATUS "IDF_TARGET is not set, guessed '${env_idf_target}' from '${conf_file}'")
            else()
                set(env_idf_target esp32)
                message(STATUS "IDF_TARGET not set, using default target: ${env_idf_target}")
            endif()
        endif()
    
    else()
        message(STATUS "IDF_TARGET defined in the enviourment variable using that ${env_idf_target}")
    endif()

    
    # Check if selected target is consistent with CMake cache
    if(DEFINED CACHE{IDF_TARGET})
        if(NOT $CACHE{IDF_TARGET} STREQUAL ${env_idf_target})
            message(FATAL_ERROR " IDF_TARGET '$CACHE{IDF_TARGET}' in CMake"
                " cache does not match currently selected IDF_TARGET '${env_idf_target}'."
                " To change the target, clear the build directory and sdkconfig file,"
                " and build the project again.")
        endif()
    endif()
    
  
    # Check if selected target is consistent with sdkconfig
    __target_from_config("${sdkconf_file}" sdkconfig_target where)
    
    if(sdkconfig_target)
        if(NOT ${sdkconfig_target} STREQUAL ${env_idf_target})
            message(FATAL_ERROR " Target '${sdkconfig_target}' in sdkconfig '${where}'"
                " does not match currently selected IDF_TARGET '${IDF_TARGET}'."
                " To change the target, clear the build directory and sdkconfig file,"
                " and build the project again.")
        endif()
    endif() 
 
   

        # checking if we support the target or not 
    if(env_idf_target MATCHES "esp32" OR env_idf_target MATCHES "esp32s3" OR env_idf_target STREQUAL "esp32c3")
        message(STATUS "${env_idf_target} target has support in the toolchain")
    else()
        message(FATAL_ERROR "${env_idf_target} mcu is not supported by the ESP-IDF")
    endif()


    # IDF_TARGET will be used by component manager, make sure it is set
    set(ENV{IDF_TARGET} ${env_idf_target})

    # Finally, set IDF_TARGET in cache
    set(IDF_TARGET ${env_idf_target} CACHE STRING "IDF Build Target for the project")
    
    # set the TARGET property for the project 
    set_property(TARGET __idf_build_target PROPERTY IDF_TARGET "${env_idf_target}")

    # set the target in the parent scope
    set(${target} "${env_idf_target}" PARENT_SCOPE)
    
endfunction()

