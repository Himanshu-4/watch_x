################################################################################
# tool_setup.cmake
# Description:
#   	setting up the toolset for the project, there are different tools that need to be checked 
#       when building esp32 programs .
#
# Notes:
#       Please dont modify existing CMAKE function and commands unless highly required 
# 		 Additional notes
#       This files should be used in main project file and 
#
################################################################################
# [Contents of the file below]
# check for minimum cmake version to run this script
cmake_minimum_required(VERSION 3.2.1)

# @name tools_inits 
#   
# @param0  target  
# @note    Init the Tools for the target 
# @usage   used in project.cmake to initialise the tools like python, git, etc
# @scope  scope   
# scope tells where should this cmake function used 
# 
function(tools_init target)
    message(STATUS "initing the toolset  for the Target ${target}")
    __tools_find_python()
    __tools_check_python()

    # find git and check 
    __tool_find_git()
    __tool_check_git_repo()

    # find the ccache program and add in prelaunch commands 
    __tool_find_ccache()

endfunction()


# @name __tool_find_git 
#   
# @note    find git tool in the specified directory 
# @usage   usage  
# @scope  scope   
# scope tells where should this cmake function used 
# 

function(__tool_find_git)
    if(DEFINED CACHE{GIT})
        message(STATUS "GIT Exists and already added to path ${GIT}")
        return()
    endif()

    get_target_property(git_path __idf_build_target PATH_GIT)
    get_target_property(build_dir __idf_build_target BUILD_DIR)

    # find the git at the path 
    find_program(git_prog "git" 
                    PATHS ${git_path}
                    REQUIRED
                    DOC "Git Version managment tool for the IDF repo"
                    NO_DEFAULT_PATH
                    NO_CMAKE_FIND_ROOT_PATH
                    )
    if(NOT EXISTS ${git_prog})
        message(FATAL_ERROR "git program doesn't exist at the path ${GIT_STANDARD_PATH} ")
    endif()

    get_filename_component(git ${git_prog} NAME)
    
    set(GIT_VERSION_SUPPORTED 2.33.0)
    # execute the process to find that this python is valid 
    execute_process(COMMAND "${git}" --version
                    WORKING_DIRECTORY "${build_dir}"
                    RESULT_VARIABLE exec_res_var 
                    OUTPUT_VARIABLE exec_out_var 
                    ERROR_VARIABLE exec_err_var
                    COMMAND_ECHO STDOUT
                    )
            # Regular expression pattern to match the version number
    set(regex_pattern "git version ([0-9]+\\.[0-9]+\\.[0-9]+)")

    # message(WARNING "res-> ${exec_res_var} out->${exec_out_var} err->${exec_err_var} ")
    # Match the pattern in the input string
    string(REGEX MATCH "${regex_pattern}" version_match "${exec_out_var}")

    # Extract the version number from the match
    if( NOT  "${CMAKE_MATCH_1}" STREQUAL "${GIT_VERSION_SUPPORTED}")
            message(WARNING "not found supported git ${GIT_VERSION_SUPPORTED} instead we got GIT ${CMAKE_MATCH_1}")
    endif()
        
    set(GIT "${git}" CACHE FILEPATH "git version control" )
    # set the git property in the global scope 
    set_property(TARGET __idf_build_target PROPERTY GIT ${git})
    set_property(TARGET __idf_build_target PROPERTY GIT_EXE_PATH ${git_path})
    

endfunction()


# @todo
function(__tool_check_git_repo)
    
endfunction()


# @name __tools_find_python 
#   
# @note   find the python program in the Enviourment and    
# @usage   usage  
# @scope  scope   
# scope tells where should this cmake function used 
# 

function(__tools_find_python )

    # check if python exist in cache string 
    if(DEFINED CACHE{PYTHON})
        set_property(TARGET __idf_build_target PROPERTY PYTHON ${PYTHON})
        set_property(TARGET __idf_build_target PROPERTY PYTHON_EXE_PATH ${PYTHON_EXE_PATH})
        message(STATUS "Python Exists and already added to path ${PYTHON}")
        return()
    endif()

    get_target_property(py_path __idf_build_target PATH_PYTHON)
    # tools can be found using found program 
    find_program(python_prog  "python" 
                    PATHS ${py_path}
                    # VALIDATOR __python_find_prog_validator validator is not working properly
                    REQUIRED 
                    DOC "python interpreter provided by the ESP-IDF"
                    NO_DEFAULT_PATH
                    NO_CMAKE_FIND_ROOT_PATH
    )

    if(NOT EXISTS ${python_prog})
        message(FATAL_ERROR "python program doesn't exist in ${py_path} ")
    endif()

    get_filename_component(python ${python_prog} NAME)
    
    set(PYTHON_VERSION_SUPPORTED 3.10.4)
    # execute the process to find that this python is valid 
    execute_process(COMMAND "${python}" --version
                    WORKING_DIRECTORY "${CMAKE_BINARY_DIR}"
                    RESULT_VARIABLE exec_res_var 
                    OUTPUT_VARIABLE exec_out_var 
                    ERROR_VARIABLE exec_err_var
                    COMMAND_ECHO STDOUT
                    )
            # Regular expression pattern to match the version number
    set(regex_pattern "Python ([0-9]+\\.[0-9]+\\.[0-9]+)")

    # message(WARNING "res-> ${exec_res_var} out->${exec_out_var} err->${exec_err_var} ")
    # Match the pattern in the input string
    string(REGEX MATCH "${regex_pattern}" version_match "${exec_out_var}")

    # Extract the version number from the match
    if( NOT  "${CMAKE_MATCH_1}" STREQUAL "${PYTHON_VERSION_SUPPORTED}")
            message(WARNING "not found supported python ${PYTHON_VERSION_SUPPORTED} instead we got python ${CMAKE_MATCH_1}")
    endif()
    
    set(PYTHON "${python}" CACHE FILEPATH "Python Interpreter for ESP-IDF" )
    set(PYTHON_EXE_PATH ${py_path} CACHE FILEPATH "python standard filepath ")
    # set the python property in the global scope 
    set_property(TARGET __idf_build_target PROPERTY PYTHON ${python})
    set_property(TARGET __idf_build_target PROPERTY PYTHON_EXE_PATH ${py_path})

endfunction()


# @name __tools_Check_python   
#    
# @note    check python packages and interpreter path, also to get this python in the global property    
# @usage   used to check the python interpreter & its installed package
# @scope  this file onyly   
# scope tells where should this cmake function used 
# 
function(__tools_check_python)
    if(DEFINED CACHE{PYTHON_DEPS_CHECKED} OR PYTHON_DEPS_CHECKED)
        message(STATUS "python checked are skipped, Already Done !!")
        return() 
    endif()
    # get the property from the target scope 
    get_property(python TARGET __idf_build_target PROPERTY PYTHON)
    get_property(idf_path TARGET __idf_build_target PROPERTY IDF_PATH)

    message(STATUS "Checking Python dependencies...")
    execute_process(COMMAND "${python}" "${idf_path}/tools/idf_tools.py" "check-python-dependencies"
            RESULT_VARIABLE result)
    if(result EQUAL 1)
        # check_python_dependencies returns error code 1 on failure
        message(FATAL_ERROR "Some Python dependencies must be installed. Check above message for details.")
    elseif(NOT result EQUAL 0)
        # means check_python_dependencies.py failed to run at all, result should be an error message
        message(FATAL_ERROR "Failed to run Python dependency check. Python: ${python}, Error: ${result}")
    endif()
    set(PYTHON_DEPS_CHECKED 1 CACHE BOOL "Python checked variable to not run the python test all the time cmake is invoked ")
endfunction()




# @name __tool_find_ccache 
#   
# @note    find the ccache programs 
# @usage   usage  
# @scope  scope   
# scope tells where should this cmake function used 
# 
function(__tool_find_ccache)  

    get_target_property(ccache_path __idf_build_target PATH_CCACHE)
    find_program(ccache_prog "ccache"
                        PATHS ${ccache_path}
                        REQUIRED
                        DOC "ccache program for faster compilation of the project"
                        NO_DEFAULT_PATH 
                        NO_CMAKE_FIND_ROOT_PATH)
    if(EXISTS ${ccache_prog})
        message(STATUS "ccache will be used for faster recompilation")
        set_property(GLOBAL PROPERTY RULE_LAUNCH_COMPILE ccache)
    else()
        message(FATAL_ERROR "ccache program is not found and is used in the build")
    endif()

endfunction()
