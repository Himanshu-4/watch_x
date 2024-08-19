################################################################################
# build.cmake
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



# ===================================================================================================
# ------------------------------------------------------------------------------------------------------

#
# Resolve the requirement component to the component target created for that component.
#
function(__build_resolve_and_add_req var component_target req type)
    __component_get_target(_component_target ${req})
    __component_get_property(_component_registered ${component_target} __COMPONENT_REGISTERED)
    if(NOT _component_target OR NOT _component_registered)
        message(FATAL_ERROR "Failed to resolve component '${req}'.")
    endif()
    __component_set_property(${component_target} ${type} ${_component_target} APPEND)
    set(${var} ${_component_target} PARENT_SCOPE)
endfunction()


# Build a list of components (in the form of component targets) to be added to the build
# based on public and private requirements. This list is saved in an internal property,
# __BUILD_COMPONENT_TARGETS.
#
function(__build_expand_requirements component_target)
    # Since there are circular dependencies, make sure that we do not infinitely
    # expand requirements for each component.
    idf_build_get_property(component_targets_seen __COMPONENT_TARGETS_SEEN)
    __component_get_property(component_registered ${component_target} __COMPONENT_REGISTERED)

    list(FIND component_targets_seen "${component_target}" res)
    if((NOT res EQUAL -1) OR (NOT component_registered))
        return()
    endif()

    idf_build_set_property(__COMPONENT_TARGETS_SEEN ${component_target} APPEND)

    get_property(reqs TARGET ${component_target} PROPERTY REQUIRES)
    get_property(priv_reqs TARGET ${component_target} PROPERTY PRIV_REQUIRES)
    __component_get_property(component_name ${component_target} COMPONENT_NAME)
    __component_get_property(component_alias ${component_target} COMPONENT_ALIAS)
    idf_build_get_property(common_reqs __COMPONENT_REQUIRES_COMMON)
    list(APPEND reqs ${common_reqs})

    if(reqs)
        list(REMOVE_DUPLICATES reqs)
        list(REMOVE_ITEM reqs ${component_alias} ${component_name})
    endif()

    foreach(req ${reqs})
        depgraph_add_edge(${component_name} ${req} REQUIRES)
        __build_resolve_and_add_req(_component_target ${component_target} ${req} __REQUIRES)
        __build_expand_requirements(${_component_target})
    endforeach()

    foreach(req ${priv_reqs})
        depgraph_add_edge(${component_name} ${req} PRIV_REQUIRES)
        __build_resolve_and_add_req(_component_target ${component_target} ${req} __PRIV_REQUIRES)
        __build_expand_requirements(${_component_target})
    endforeach()

    idf_build_get_property(build_component_targets __BUILD_COMPONENT_TARGETS)
    list(FIND build_component_targets "${component_target}" res)
    if(res EQUAL -1)
        idf_build_set_property(__BUILD_COMPONENT_TARGETS ${component_target} APPEND)

        __component_get_property(component_lib ${component_target} COMPONENT_LIB)
        idf_build_set_property(__BUILD_COMPONENTS ${component_lib} APPEND)

        idf_build_get_property(prefix __PREFIX)
        __component_get_property(component_prefix ${component_target} __PREFIX)

        __component_get_property(component_alias ${component_target} COMPONENT_ALIAS)

        idf_build_set_property(BUILD_COMPONENT_ALIASES ${component_alias} APPEND)

        # Only put in the prefix in the name if it is not the default one
        if(component_prefix STREQUAL prefix)
            __component_get_property(component_name ${component_target} COMPONENT_NAME)
            idf_build_set_property(BUILD_COMPONENTS ${component_name} APPEND)
        else()
            idf_build_set_property(BUILD_COMPONENTS ${component_alias} APPEND)
        endif()
    endif()
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
                    "-DESP_PLATFORM"
                    # "IDF_VER=\\\"idf_ver_git\\\""
                    "-DSOC_MMU_PAGE_SIZE=CONFIG_MMU_PAGE_SIZE"
                    "-D_GNU_SOURCE"
                    "-DconfigENABLE_FREERTOS_DEBUG_OCDAWARE=1"
                    # @todo this should be set by build_get_idf_git_revision 
                    "-DIDF_VER=${PROJECT_SDK_VERSION}"

                    ${COMPILER_DEFINATION}
                    )
                    
    if(NOT BOOTLOADER_BUILD)
        list(APPEND compile_definitions "-D_POSIX_READER_WRITER_LOCKS" )

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

    spaces2list(COMPILER_C_OPTIONS)
    spaces2list(COMPILER_CXX_OPTIONS)
    spaces2list(COMPILER_ASM_OPTIONS)

    # set the compiler flags for all the build compopnents in the directory z
    idf_build_set_property(COMPILE_DEFINITIONS "${compile_definitions}" APPEND)
    idf_build_set_property(COMPILE_OPTIONS "${compile_flags}" APPEND)
    
    idf_build_set_property(C_COMPILE_OPTIONS "${compile_flags}" "${COMPILER_C_OPTIONS}" APPEND)
    idf_build_set_property(CXX_COMPILE_OPTIONS "${compile_flags}" "${COMPILER_CXX_OPTIONS}" APPEND)
    idf_build_set_property(ASM_COMPILE_OPTIONS "${compile_flags}" "${COMPILER_ASM_OPTIONS}" APPEND)

endfunction()



# @name __build_set_defaults_prop 
#   
# @note    Note   
# @usage   usage  
# @scope  scope   
# scope tells where should this cmake function used 
# 
function(__build_set_defaults_prop)
    idf_build_set_property(__PREFIX idf)

    idf_build_get_property(build_dir BUILD_DIR)
    # also generate a build components dir in build dir 
    file(MAKE_DIRECTORY "${build_dir}/components")

    # set the env fpga to false, as we are not building for fpga enviourment  
    set(ENV{IDF_ENV_FPGA} 0)
    
    idf_build_set_property(__IDF_ENV_FPGA 0)
    set_property(GLOBAL PROPERTY __IDF_ENV_SET 1)

    # if bootloader build
    idf_build_set_property(BOOTLOADER_BUILD "${BOOTLOADER_BUILD}")
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
function(build_init  target) 
   
    # init the deafult build specs and lang version done in the toolchain_file.cmake
    __build_set_defaults_prop()

    # init the basic compiler flags as of known and that are common for all targets 
    __build_set_default_build_flags()

    #  call the init process of the ldgen tool
    # this init the ld process files 
    ldgen_init()

    # call the kconfig init 
    kconfig_init()

    if("${target}" STREQUAL "esp32" OR "${target}" STREQUAL "esp32s2" OR "${target}" STREQUAL "esp32s3")
        idf_build_set_property(IDF_TARGET_ARCH "xtensa")
    elseif("${target}" STREQUAL "linux")
        # No arch specified for linux host builds at the moment
        idf_build_set_property(IDF_TARGET_ARCH "")
    else()
        idf_build_set_property(IDF_TARGET_ARCH "riscv")
    endif()

    if("${target}" STREQUAL "linux")
        set(requires_common freertos log esp_rom esp_common)
        idf_build_set_property(__COMPONENT_REQUIRES_COMMON "${requires_common}")
    else()
        # add the common components 
        set(requires_common cxx newlib freertos esp_hw_support heap log soc hal esp_rom esp_common esp_system)
        idf_build_set_property(__COMPONENT_REQUIRES_COMMON "${requires_common}")
    endif()
    if(NOT "${target}" STREQUAL "linux")
        idf_build_set_property(__COMPONENT_REQUIRES_COMMON ${arch} APPEND)
    endif()


endfunction()






