################################################################################
# bin.cmake
#
# Author: [Himanshu Jangra]
# Date: [6-Mar-2024]
#
# Description:
#   	bin.cmake is the dump for collecting the garbae function .
#
# Notes:
#       Please dont modify existing CMAKE function and commands unless highly required 
# 		 Additional notes
#
################################################################################
# [Contents of the file below]
# check for minimum cmake version to run this script
cmake_minimum_required(VERSION 3.2.1)


# @name component_dir_quick_check 
#   
# @param0  var
# @param1  component_dir 
# @note    used to check whether the dir contians component or not 
# @usage   used in build.cmake or idf.cmake
# @scope  scope   
# scope tells where should this cmake function used 
# 
function(__component_dir_quick_check component_name component_dir)
    set(res "")
    # fetch the directory name 
    get_filename_component(abs_dir ${component_dir} ABSOLUTE)

    # fetch the component name 
    get_filename_component(comp_name ${abs_dir} NAME)
    string(SUBSTRING "${comp_name}" 0 1 first_char)

    # Check the component directory contains a CMakeLists.txt file
    # - warn and skip anything which isn't valid looking (probably cruft)
    if(NOT first_char STREQUAL ".")
        if(NOT EXISTS "${abs_dir}/CMakeLists.txt")
            # message(STATUS "Component directory ${abs_dir} does not contain a CMakeLists.txt file. "
            #     "No component will be added")
            set(res "")
        else()
            set(res "${comp_name}")
        endif()
    else()
        set(res "") # quietly ignore dot-folders
    endif()

    set(${component_name} ${res} PARENT_SCOPE)
endfunction()

# @name __get_components 
#   
# @param0  comps 
# @param1  comps_path 
# @note    find the components in the components path    
# @usage   used in idf_build_components  
# @scope  scope   
# scope tells where should this cmake function used 
# 
function(__get_components comps comps_path )
    
    set(components "")
    get_filename_component(comps_path ${comps_path} ABSOLUTE)
    if(NOT EXISTS ${comps_path})
        message(FATAL_ERROR "${comps_path} path doesn't valid Path that contain COMPONENTS")
    endif()

    file(GLOB  build_comps_dirs "${comps_path}/*" )

    foreach(comp_dir ${build_comps_dirs})
        __component_dir_quick_check(comp_name ${comp_dir})
        if(comp_name)
            list(APPEND components ${comp_name})
        endif()
    endforeach()
    
    # execute this command in parent scope
    set(${comps} ${components} PARENT_SCOPE)
endfunction()



 # filter out the components that are required by the user and their dependency
    # also if a component is missing stop the build process  
function(__filter_components filter_comps all_comps)
    # get essential components 
    idf_build_get_property(build_ess_comps BUILD_COMPONENTS)
    set(filtercomps "")
    foreach(comps ${all_comps})
        # doesn't expand the list just give the list name 
        list(FIND build_ess_comps ${comps} res)
        # check if element found 
        if(NOT res EQUAL -1)
            list(APPEND filtercomps ${comps})
        endif()
    endforeach()
    
    set(${filter_comps} ${filtercomps} PARENT_SCOPE)
endfunction()

    show the build components to the users , also show the target name
