################################################################################
# project_conf.cmake
#
# Author: [Himanshu Jangra]
# Date: [23-July-2024]
#
# Description:
#   	read the project configuration file and init the configuration 
#       based on the config file .
#
# Notes:
#       Please dont modify existing CMAKE function and commands unless highly required 
# 		 Additional notes
#
################################################################################
# [Contents of the file below]
# check for minimum cmake version to run this script
cmake_minimum_required(VERSION 3.2.1)




function(read_entry_points)
    
endfunction()


function(get_paths_vars)
    
endfunction()


function(get_compile_flags)
    
endfunction()



function(__check_conf_type line)

endfunction()



# @name __read_conf_file 
#   
# @param0  conf_file
# @note    this is the config file that would be used 
#          for the project top level configuration 
# @usage   used to init some stuff defined in the configuration
# @scope  root file
# scope tells where should this cmake function used 
# 
function(__read_conf_file conf_file)

    if(NOT EXISTS ${conf_file})
        message(FATAL_ERROR "the configuration file ${conf_file} doesn't exist")
    endif()
    
    file(READ "${conf_file}" file_content)
    # the newline character depends on the host system 
    if(DEFINED ENV{MSYSTEM} OR CMAKE_HOST_WIN32)
        set(line_ending "\r\n")
    else() # unix
        set(line_ending "\n" )
    endif()

    string(REPLACE ${line_ending} ";" file_lines "${file_content}")

    list(LENGTH file_lines list_len)
    set(current_len 0)

    while(current_len < list_len)
        
    # read and decode the list 
    endwhile()
    
    # read each line 
    foreach(line ${file_lines})
        # print the lines 
        message(STATUS "${line}")
        # string(STRIP "${line}" line)
        # if(line MATCHES "^[#;]")
        #     continue()  # Skip comments
        # endif()
        # if(line MATCHES "^[[]")
        #     set(section ${line})
        #     continue()
        # endif()
        # if(line MATCHES "^(.*)=(.*)$")
        #     string(STRIP "${CMAKE_MATCH_1}" key)
        #     string(STRIP "${CMAKE_MATCH_2}" value)
        #     set("${section}_${key}" "${value}")
        # endif()
    endforeach()


endfunction()
