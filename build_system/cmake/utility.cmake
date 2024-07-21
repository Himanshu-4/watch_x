################################################################################
# utility.cmake
#
# Author: [Himanshu Jangra]
# Date: [22-Feb-2024]
#
# Description:
#   This CMake script is used for common utility functions that would be used in our Project and it contains the scripts 
#    used for building the project.
#
# Notes:
#       Please dont modify existing CMAKE function and commands unless highly required 
#
################################################################################

# [Contents of the file below]

# check for minimum cmake version to run this script 
cmake_minimum_required(VERSION 3.2)

# include(${CMAKE_CURRENT_LIST_DIR}/custom_log.cmake)

# @name set_defualt 
#   
# @param0  variable 
# @param1  default_Value 
# @note    Set a varibale with the default value if it is not defined earlier   
# @usage   should only in this directory 
# @scope   Parent_scope   
# scope tells where should this cmake function used 
# 

function(set_default variable default_value)
    if(NOT ${variable})
        if(DEFINED ENV{${variable}} AND NOT "$ENV{${variable}}" STREQUAL "")
            set(${variable} $ENV{${variable}} PARENT_SCOPE)
        else()
            set(${variable} ${default_value} PARENT_SCOPE)
        endif()
    endif()
endfunction()

# spaces2list
#
# Take a variable whose value was space-delimited values, convert to a cmake
# list (semicolon-delimited)
#
# Note: do not use this for directories or full paths, as they may contain
# spaces.
#
# TODO: look at cmake separate_arguments, which is quote-aware
function(spaces2list variable_name)
    string(REPLACE " " ";" tmp "${${variable_name}}")
    set("${variable_name}" "${tmp}" PARENT_SCOPE)
endfunction()

# lines2list
#
# Take a variable with multiple lines of output in it, convert it
# to a cmake list (semicolon-delimited), one line per item
#
function(lines2list variable_name)
    string(REGEX REPLACE "\r?\n" ";" tmp "${${variable_name}}")
    string(REGEX REPLACE ";;" ";" tmp "${tmp}")
    set("${variable_name}" "${tmp}" PARENT_SCOPE)
endfunction()

# convert_path_to_cmake
#
# convert input file or dir name  into format suitable for cmake scripts
# adjusting path seperators and handling platform specific differences  
# @param = please sepcify the arguments as 
# 
function(convert_cmake_paths paths)
    set(res "")
    # search for all the values in the paths 
    foreach(val "${${paths}}")
        file(TO_CMAKE_PATH  "${val}" out_var)
        list(APPEND res "${out_var}")
    endforeach()
    set(${paths} "${res}" PARENT_SCOPE)
endfunction()




# @name move_it_different  
#   
# @param0  source 
# @param1  destination 
# @note    If 'source' has different md5sum to 'destination' (or destination
# does not exist, move it across.
# If 'source' has the same md5sum as 'destination', delete 'source'.
# Avoids timestamp updates for re-generated files where content hasn't
# changed.
#
# @usage   
# @scope parent_scope     
# scope tells where should this cmake function used 
# @todo



# Append a single line to the file specified
# The line ending is determined by the host OS

# @name file_append_line 
#   
# @param0  file
# @param1  line 
# @note    append a single line to the file specified, line ending is determined by host os    
# @usage   if u want to add something in file 
# @scope  parent scope   
# scope tells where should this cmake function used 
# 
function(file_append_line file line)
    if(DEFINED ENV{MSYSTEM} OR CMAKE_HOST_WIN32)
        set(line_ending "\r\n")
    else() # unix
        set(line_ending "\n")
    endif()
    file(READ ${file} existing)
    # start searching from the end of the file
    string(FIND ${existing} ${line_ending} last_newline REVERSE)
    string(LENGTH ${existing} length)
    math(EXPR length "${length}-1")
    if(NOT length EQUAL last_newline) # file doesn't end with a newline
        file(APPEND "${file}" "${line_ending}")
    endif()
    #  append this line at last  
    file(APPEND "${file}" "${line}${line_ending}")
endfunction()



# Convert a CMake list to a JSON list and store it in a variable
function(make_json_list list variable)
    list(LENGTH list length)
    if(${length})
        string(REPLACE ";" "\", \"" result "[ \"${list}\" ]")
    else()
        set(result "[]")
    endif()
    set("${variable}" "${result}" PARENT_SCOPE)
endfunction()

# add_prefix
#
# Adds a prefix to each item in the specified list.
#
# @name add_prefix 
#   
# @param0  var 
# @param1  prefix
# @note      Add a prefix to each item in the specified list, can be one item 
# @usage   used to add prefix for the items 
# @scope  scope   
# scope tells where should this cmake function used 
# 
function(add_prefix var prefix)
    foreach(elm ${ARGN})
        list(APPEND newlist "${prefix}${elm}")
    endforeach()
    set(${var} "${newlist}" PARENT_SCOPE)
endfunction()


# @name fail_at_build_time 
#   
# @param0  target_name
# @param1  message_line0 
# @note     Creates a phony target which fails the build and touches CMakeCache.txt to cause a cmake run next time.
# This is used when a missing file is required at CMake runtime, but we can't fail the build if it is not found,
# because the "menuconfig" target may be required to fix the problem.
# We cannot use CMAKE_CONFIGURE_DEPENDS instead because it only works for files which exist at CMake runtime.
#    
# @usage   usage  
# @scope  scope   
# scope tells where should this cmake function used 
# 
function(fail_at_build_time target_name message_line0)
    # get the build cmake path 
    idf_build_get_property(cmake_scripts_path CMAKE_SCRIPTS_PATH)

    set(message_lines COMMAND ${CMAKE_COMMAND} -E echo "${message_line0}")
    # foreach(message_line ${ARGN})
    #     set(message_lines ${message_lines} COMMAND ${CMAKE_COMMAND} -E echo "${message_line}")
    # endforeach()
    foreach(line ${ARGN})
        list(APPEND message_lines  COMMAND ${CMAKE_COMMAND} -E echo "${line}")
    endforeach()
    
    # Generate a timestamp file that gets included. When deleted on build, this forces CMake
    # to rerun.
    string(RANDOM filename)
    set(filename "${CMAKE_CURRENT_BINARY_DIR}/random_files/${filename}.cmake")
    file(WRITE "${filename}" "")
    include("${filename}")
    set(fail_message "Failing the build (see errors on lines above)")
    add_custom_target(${target_name} ALL
        ${message_lines}
        COMMAND ${CMAKE_COMMAND} -E remove "${filename}"
        COMMAND ${CMAKE_COMMAND} -E env FAIL_MESSAGE=${fail_message}
                ${CMAKE_COMMAND} -P ${cmake_scripts_path}/scripts/fail.cmake
        VERBATIM)
endfunction()



# fail_target
#
# Creates a phony target which fails when invoked. This is used when the necessary conditions
# for a target are not met, such as configuration. Rather than ommitting the target altogether,
# we fail execution with a helpful message.
function(fail_target target_name message_line0)
    idf_build_get_property(cmake_scripts_path  CMAKE_SCRIPTS_PATH )
    set(message_lines COMMAND ${CMAKE_COMMAND} -E echo "${message_line0}")
    foreach(message_line ${ARGN})
        set(message_lines ${message_lines} COMMAND ${CMAKE_COMMAND} -E echo "${message_line}")
    endforeach()
    # Generate a timestamp file that gets included. When deleted on build, this forces CMake
    # to rerun.
    set(fail_message "Failed executing target (see errors on lines above)")
    add_custom_target(${target_name}
        ${message_lines}
        COMMAND ${CMAKE_COMMAND} -E env FAIL_MESSAGE=${fail_message}
                ${CMAKE_COMMAND} -P ${cmake_scripts_path}/scripts/fail.cmake
        VERBATIM)
endfunction()


function(check_exclusive_args args prefix)
    set(_args ${args})
    spaces2list(_args)
    set(only_arg 0)
    foreach(arg ${_args})
        if(${prefix}_${arg} AND only_arg)
            message(FATAL_ERROR "${args} are exclusive arguments")
        endif()

        if(${prefix}_${arg})
            set(only_arg 1)
        endif()
    endforeach()
endfunction()


# add_compile_options variant for C++ code only
#
# This adds global options, set target properties for
# component-specific flags
function(add_cxx_compile_options)
    foreach(option ${ARGV})
        # note: the Visual Studio Generator doesn't support this...
        add_compile_options($<$<COMPILE_LANGUAGE:CXX>:${option}>)
    endforeach()
endfunction()

# add_compile_options variant for C code only
#
# This adds global options, set target properties for
# component-specific flags
function(add_c_compile_options)
    foreach(option ${ARGV})
        # note: the Visual Studio Generator doesn't support this...
        add_compile_options($<$<COMPILE_LANGUAGE:C>:${option}>)
    endforeach()
endfunction()

# add_compile_options variant for ASM code only
#
# This adds global options, set target properties for
# component-specific flags
function(add_asm_compile_options)
    foreach(option ${ARGV})
        # note: the Visual Studio Generator doesn't support this...
        add_compile_options($<$<COMPILE_LANGUAGE:ASM>:${option}>)
    endforeach()
endfunction()



# file_generate
#
# Utility to generate file and have the output automatically added to cleaned files.
function(file_generate output)
    cmake_parse_arguments(_ "" "INPUT;CONTENT" "" ${ARGN})

    if(__INPUT)
        file(GENERATE OUTPUT "${output}" INPUT "${__INPUT}")
    elseif(__CONTENT)
        file(GENERATE OUTPUT "${output}" CONTENT "${__CONTENT}")
    else()
        message(FATAL_ERROR "Content to generate not specified.")
    endif()

    set_property(DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}"
        APPEND PROPERTY ADDITIONAL_CLEAN_FILES "${output}")
endfunction()


# @name add_subdirectory  
#   
# @param0  source_dir  
# @note    add the subdirectory if exist otherwise skip the directory 
# @usage   usage  
# @scope  scope   
# scope tells where should this cmake function used 
# 
function(__add_subdirectory source_dir)
    set(options EXCLUDE_FROM_ALL)
    set(single_value "")
    set(multi_value "")
    cmake_parse_arguments(_ "${options}" "${single_value}" "${multi_value}" ${ARGN})

    # parse the binary directory if specified 
    get_filename_component(abs_dir "${source_dir}"
        ABSOLUTE BASE_DIR "${CMAKE_CURRENT_LIST_DIR}")
    if(EXISTS "${abs_dir}")
        add_subdirectory("${source_dir}" ${ARG0} ${__EXCLUDE_FROM_ALL})
    else()
        message(FATAL_ERROR "Subdirectory '${abs_dir}' does not exist, skipped.")
    endif()
endfunction()


# add_deprecated_target_alias
#
# Creates an alias for exising target and shows deprectation warning
function(add_deprecated_target_alias old_target new_target)
    add_custom_target(${old_target}
     # `COMMAND` is important to print the `COMMENT` message at the end of the target action.
        COMMAND ${CMAKE_COMMAND} -E echo ""
        COMMENT "Warning: command \"${old_target}\" is deprecated. Have you wanted to run \"${new_target}\" instead?"
        DEPENDS  ${new_target}
        )
        # add_depedndecies can be used here 
endfunction()


# Remove duplicates from a string containing compilation flags
function(remove_duplicated_flags FLAGS UNIQFLAGS)
    set(FLAGS_LIST "${FLAGS}")
    # Convert the given flags, as a string, into a CMake list type
    separate_arguments(FLAGS_LIST)
    # Remove all the duplicated flags
    list(REMOVE_DUPLICATES FLAGS_LIST)
    # Convert the list back to a string
    string(REPLACE ";" " " FLAGS_LIST "${FLAGS_LIST}")
    # Return that string to the caller
    set(${UNIQFLAGS} "${FLAGS_LIST}" PARENT_SCOPE)
endfunction()
