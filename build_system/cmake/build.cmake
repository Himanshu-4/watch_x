################################################################################
# build.cmake
#
# Author: [Himanshu Jangra]
# Date: [22-Feb-2024]
#
# Description:
#   	this file contains the build regarding stuff like a dummy target so that to fetch some properties 
#
# Notes:
#       Please dont modify existing CMAKE function and commands unless highly required 
# 		 Additional notes
#
################################################################################
# [Contents of the file below]
# check for minimum cmake version to run this script
cmake_minimum_required(VERSION 3.2.1)

include(ldgen)

# idf_build_get_property
#
# @brief Retrieve the value of the specified property related to ESP-IDF build.
#
# @param[out] var the variable to store the value in
# @param[in] property the property to get the value of
#
# @param[in, optional] GENERATOR_EXPRESSION (option) retrieve the generator expression for the property
#                   instead of actual value
function(idf_build_get_property var property)
    cmake_parse_arguments(_ "GENERATOR_EXPRESSION" "" "" ${ARGN})
    if(__GENERATOR_EXPRESSION)
        set(val "$<TARGET_PROPERTY:__idf_build_target,${property}>")
    else()
        get_property(val TARGET __idf_build_target PROPERTY ${property})
    endif()
    set(${var} ${val} PARENT_SCOPE)
endfunction()


#
# # Perform any fixes or adjustments to the values stored in IDF build properties.
# # This function only gets called from 'idf_build_set_property' and doesn't affect
# # the properties set directly via 'set_property'.
# #
macro(__build_fixup_property  property value)
    # Fixup COMPILE_DEFINITIONS property to support -D prefix, which had to be used in IDF v4.x projects.
    if(property STREQUAL "COMPILE_DEFINITIONS" AND NOT "${${value}}" STREQUAL "")
        string(REGEX REPLACE "^-D" "" stripped_value "${${value}}")
        set("${value}" "${stripped_value}")
        message(STATUS "Fixing Compile definations for --->  ${${value}}  ")
    endif()
endmacro()

# idf_build_set_property
#
# @brief Set the value of the specified property related to ESP-IDF build. The property is
#        also added to the internal list of build properties if it isn't there already.
#
# @param[in] property the property to set the value of
# @param[out] value value of the property
#
# @param[in, optional] APPEND (option) append the value to the current value of the
#                     property instead of replacing it
function(idf_build_set_property property value)
    cmake_parse_arguments(_ "APPEND" "" "" ${ARGN})

    # Fixup property value, e.g. for compatibility. (Overwrites variable 'value'.)
    # __build_fixup_property("${property}" value)
    # __build_fixup_property("${property}" "${value}" value)

    if(__APPEND)
        set_property(TARGET __idf_build_target APPEND PROPERTY ${property} ${value})
    else()
        set_property(TARGET __idf_build_target PROPERTY ${property} ${value})
    endif()

    ### include all the build properties in the __BUILD_PROPERTIES 
    # Keep track of set build properties so that they can be exported to a file that
    # will be included in early expansion script.
    idf_build_get_property(build_properties __BUILD_PROPERTIES)
    list(FIND build_properties "${property}" found_prop)
    if(found_prop EQUAL -1)
        idf_build_set_property(__BUILD_PROPERTIES "${property}" APPEND)
    endif()
endfunction()

# idf_build_unset_property
#
# @brief Unset the value of the specified property related to ESP-IDF build. Equivalent
#        to setting the property to an empty string; though it also removes the property
#        from the internal list of build properties.
#
# @param[in] property the property to unset the value of
function(idf_build_unset_property property)
    idf_build_set_property(${property} "") # set to an empty value
    idf_build_get_property(build_properties __BUILD_PROPERTIES) # remove from tracked properties
    list(REMOVE_ITEM build_properties ${property})
    idf_build_set_property(__BUILD_PROPERTIES "${build_properties}")
endfunction()

#
# Retrieve the IDF_PATH repository's version, either using a version
# file or Git revision. Sets the IDF_VER build property.
#
function(__build_get_idf_git_revision)
    idf_build_get_property(idf_path IDF_PATH)

    # get the git version 
    git_describe(idf_ver_git "${idf_path}" "--match=v*.*")
    if(EXISTS "${idf_path}/version.txt")
        file(STRINGS "${idf_path}/version.txt" idf_ver_t)
        set_property(DIRECTORY APPEND PROPERTY CMAKE_CONFIGURE_DEPENDS "${idf_path}/version.txt")
    else()
        set(idf_ver_t idf_ver_git)
    endif()
    
    # cut IDF_VER to required 32 characters.
    string(SUBSTRING "${idf_ver_t}" 0 31 idf_ver)
    idf_build_set_property(COMPILE_DEFINITIONS "IDF_VER=\"${idf_ver}\"" APPEND)
    git_submodule_check("${idf_path}")
    idf_build_set_property(IDF_VER ${idf_ver})
endfunction()



# @name target_linker_script 
#   
# @param0   target 
# @param1   dependency type 
# @param2   script_files
# @note    add linkerscript to target , auto add -L serach path and -T with filename only this 
#       to include other linkerscript into the same directory
# @usage   add linkerscript to the target  
# @scope  parent_scope   
# scope tells where should this cmake function used 
# 
function(target_linker_script target deptype scriptfiles)
    cmake_parse_arguments(_ "" "PROCESS" "" ${ARGN})

    foreach(scriptfile ${scriptfiles})
        get_filename_component(abs_script "${scriptfile}" ABSOLUTE)
        message(STATUS "Adding linker script ${abs_script} for the target ${target}")

        # check if we have to process some linker script
        if(__PROCESS)
            get_filename_component(input_file "${__PROCESS}" ABSOLUTE)
            __ldgen_process_template(${target} ${input_file} ${abs_script})
            # set(abs_script ${output})
        endif()

        get_filename_component(search_dir "${abs_script}" DIRECTORY)
        get_filename_component(scriptname "${abs_script}" NAME)


        ### deptype can be PUBLIC, INTERFACE or  PRIVATE  
        # adding search path to linker file
        target_link_directories("${target}" "${deptype}" ${search_dir})
        # Regarding the usage of SHELL, see
        # https://cmake.org/cmake/help/latest/command/target_link_options.html#option-de-duplication
        target_link_options("${target}" "${deptype}" "SHELL:-T ${scriptname}")

        # Note: In ESP-IDF, most targets are libraries and libary LINK_DEPENDS don't propagate to
        # executable(s) the library is linked to. Since CMake 3.13, INTERFACE_LINK_DEPENDS is
        # available to solve this. However, when GNU Make generator is used, this property also
        # propagates INTERFACE_LINK_DEPENDS dependencies to other static libraries.
        # TODO: see if this is an expected behavior and possibly report this as a bug to CMake.
        # For the time being, record all linker scripts in __LINK_DEPENDS and attach manually to
        # the executable target once it is known.
        if(NOT __PROCESS)
            idf_build_set_property(__LINK_DEPENDS ${abs_script} APPEND)
        endif()
    endforeach()
endfunction()


# add_prebuild_library
#
# Add prebuilt library with support for adding dependencies on ESP-IDF components.
function(add_prebuilt_library target_name lib_path)
    cmake_parse_arguments(_ "" "" "REQUIRES;PRIV_REQUIRES" ${ARGN})

    get_filename_component(lib_path "${lib_path}"
                ABSOLUTE BASE_DIR "${CMAKE_CURRENT_LIST_DIR}")

    add_library(${target_name} STATIC IMPORTED)
    set_property(TARGET ${target_name} PROPERTY IMPORTED_LOCATION ${lib_path})

    foreach(req ${__REQUIRES})
        idf_component_get_property(req_lib "${req}" COMPONENT_LIB)
        set_property(TARGET ${target_name} APPEND PROPERTY LINK_LIBRARIES "${req_lib}")
        set_property(TARGET ${target_name} APPEND PROPERTY INTERFACE_LINK_LIBRARIES "${req_lib}")
    endforeach()

    foreach(req ${__PRIV_REQUIRES})
        idf_component_get_property(req_lib "${req}" COMPONENT_LIB)
        set_property(TARGET ${target_name} APPEND PROPERTY LINK_LIBRARIES "${req_lib}")
        set_property(TARGET ${target_name} APPEND PROPERTY INTERFACE_LINK_LIBRARIES "$<LINK_ONLY:${req_lib}>")
    endforeach()
endfunction()


# @name __build_set_defult_build_specs 
#   
# @note    set initial list of build specs like compiler flags, definations 
#           for all lib build under the ESP-IDF build system    
# @usage   usage  
# @scope  scope   
# scope tells where should this cmake function used 
# 
function(__build_set_default_build_flags)

    set(compile_definitions 
                    "ESP_PLATFORM"
                    # "IDF_VER=\\\"idf_ver_git\\\""
                    "SOC_MMU_PAGE_SIZE=CONFIG_MMU_PAGE_SIZE"
                    "_GNU_SOURCE"
                    "configENABLE_FREERTOS_DEBUG_OCDAWARE=1"
                    # @todo this should be set by build_get_idf_git_revision 
                    IDF_VER= "${SDK_VERSION}"
                    )
                    
    if(NOT BOOTLOADER_BUILD)
        list(APPEND compile_definitions "_POSIX_READER_WRITER_LOCKS" )

    endif()
    set (compile_flags       

                                    "-fno-builtin-memcpy"
                                    "-fno-builtin-memset" 
                                    "-fno-builtin-bzero" 
                                    "-fno-builtin-stpcpy"
                                    "-fno-builtin-strncpy" 
                                    "-fno-jump-tables"
                                    "-fno-tree-switch-conversion"
                                    
                                    "-freorder-blocks"
                                    # "-mtext-section-literals"
                                    
                                    # Default is dwarf-5 since GCC 11, fallback to dwarf-4 because of binary size
                                    # TODO: IDF-5160
                                    "-gdwarf-4"
                                    # always generate debug symbols (even in release mode, these don't
                                    # go into the final binary so have no impact on size
                                    "-ggdb"
                                    # GCC flag used in ESP32 development to enable function calls to distant memory regions,
                                    #  particularly Flash memory, allowing for more flexible memory usage in embedded applications.
                                    "-mlongcalls"
                                    "-fdiagnostics-color=always"
                                    "-fstrict-volatile-bitfields"
                                    "-ffunction-sections"
                                    "-fdata-sections"
                                    
                                    # warning-related flags
                                    "-Wall"
                                    "-Werror=all"
                                    "-Wextra"

                                    "-Wno-frame-address"
                                    "-Wno-error=unused-function"
                                    "-Wno-error=unused-variable"
                                    "-Wno-error=unused-but-set-variable"
                                    "-Wno-error=deprecated-declarations"
                                    "-Wno-unused-parameter"
                                    "-Wno-sign-compare"
                                    # ignore multiple enum conversion warnings since gcc 11
                                    # TODO: IDF-5163
                                    "-Wno-enum-conversion"

                                    )
    # set the compile definations and flags as common 
    # set(COMMON_OPTIONS "${compile_flags}" CACHE STRING "compile flags for the target")
    # set(COMMON_DEFINES "${compile_definitions}" CACHE STRING "common defines for the target")

    # # get the idf components path and set this property there 
    # get_property(build_comps_dir GLOBAL PROPERTY BUILD_COMPONENTS_PATH)
    # if(NOT EXISTS "${build_comps_dir}")
    #     message(FATAL_ERROR "Build component directory is missing and is required by the build process")
    # endif()

    
    # set the compiler flags for all the build compopnents in the directory z
    idf_build_set_property(COMPILE_DEFINITIONS "${compile_definitions}" APPEND)
    idf_build_set_property(COMPILE_OPTIONS "${compile_flags}" APPEND)
    idf_build_set_property(COMPILE_OPTIONS "-Wno-old-style-declaration" APPEND)        
    
    idf_build_set_property(C_COMPILE_OPTIONS "${compile_flags}" APPEND)
    idf_build_set_property(C_COMPILE_OPTIONS "-Wno-old-style-declaration" APPEND)
    
    idf_build_set_property(CXX_COMPILE_OPTIONS "${compile_flags}" APPEND)
    idf_build_set_property(ASM_COMPILE_OPTIONS "${compile_flags}" APPEND)
    
endfunction()



# @name __build_set_default_lang_version 
#   
# @note    Note   
# @usage   usage  
# @scope  scope   
# scope tells where should this cmake function used 
# 
function(__build_set_defaults_prop)

    idf_build_set_property(__PREFIX idf)
    idf_build_set_property(BUILD_DIR ${CMAKE_BINARY_DIR})
    # the c standard is defined in the toolchain file but we can override it here according 
    # to specified in the sdkconfig.cmake file 
    # get the build standard property 
endfunction()

# @name build_init 
#    
# @note    initalise the basic build enviourment for the target mcu
# @usage   used in idf_init or in the project.cmake init 
# @scope  parent scope
# scope tells where should this cmake function used 
# 
function(build_env_init)
   
    # init the deafult build specs and lang version done in the toolchain_file.cmake
    __build_set_defaults_prop()

    # init the basic compiler flags as of known and that are common for all targets 
    __build_set_default_build_flags()

    #  call the init process of the ldgen tool
    # this init the ld process files 
    ld_ldgen_env_init()

    kconfig_init()

endfunction()






