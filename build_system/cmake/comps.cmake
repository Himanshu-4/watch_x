################################################################################
# Components.cmake
#
# Author: [Himanshu Jangra]
# Date: [27-Feb-2024]
#
# Description:
#   	this files helps in to find the components and include in the build.
#
# Notes:
#       Please dont modify existing CMAKE function and commands unless highly required 
# 		 Additional notes
#
################################################################################
# [Contents of the file below]
# check for minimum cmake version to run this script
cmake_minimum_required(VERSION 3.2.1)

# include the component commands that will be used here 
include(comps_command)


# idf_component_register
#
# @brief Register a component to the build, creating component library targets etc.
#
# @param[in, optional] SRCS (multivalue) list of source files for the component
# @param[in, optional] SRC_DIRS (multivalue) list of source directories to look for source files
#                       in (.c, .cpp. .S); ignored when SRCS is specified.
# @param[in, optional] EXCLUDE_SRCS (multivalue) used to exclude source files for the specified
#                       SRC_DIRS
# @param[in, optional] INCLUDE_DIRS (multivalue) public include directories for the created component library
# @param[in, optional] PRIV_INCLUDE_DIRS (multivalue) private include directories for the created component library
# @param[in, optional] LDFRAGMENTS (multivalue) linker script fragments for the component
# @param[in, optional] REQUIRES (multivalue) publicly required components in terms of usage requirements
# @param[in, optional] PRIV_REQUIRES (multivalue) privately required components in terms of usage requirements
#                      or components only needed for functions/values defined in its project_include.cmake
# @param[in, optional] REQUIRED_IDF_TARGETS (multivalue) the list of IDF build targets that the component only supports
# @param[in, optional] EMBED_FILES (multivalue) list of binary files to embed with the component
# @param[in, optional] EMBED_TXTFILES (multivalue) list of text files to embed with the component
# @param[in, optional] KCONFIG (single value) override the default Kconfig
# @param[in, optional] KCONFIG_PROJBUILD (single value) override the default Kconfig
# @param[in, optional] WHOLE_ARCHIVE (option) link the component as --whole-archive
function(idf_component_register)
    set(options WHOLE_ARCHIVE)
    set(single_value KCONFIG KCONFIG_PROJBUILD)
    set(multi_value SRCS SRC_DIRS EXCLUDE_SRCS
                    INCLUDE_DIRS PRIV_INCLUDE_DIRS LDFRAGMENTS REQUIRES
                    PRIV_REQUIRES REQUIRED_IDF_TARGETS EMBED_FILES EMBED_TXTFILES)
    cmake_parse_arguments(_ "${options}" "${single_value}" "${multi_value}" ${ARGN})

    if(NOT __idf_component_context)
        message(FATAL_ERROR "Called idf_component_register from a non-component directory.")
    endif()

    __component_check_target()
    __component_add_sources(sources)

    # Add component manifest to the list of dependencies
    set_property(DIRECTORY APPEND PROPERTY CMAKE_CONFIGURE_DEPENDS "${COMPONENT_DIR}/idf_component.yml")

    # Create the final target for the component. This target is the target that is
    # visible outside the build system.
    __component_get_target(component_target ${COMPONENT_ALIAS})
    __component_get_property(component_lib ${component_target} COMPONENT_LIB)

    # Use generator expression so that users can append/override flags even after call to
    # idf_build_process
    idf_build_get_property(include_directories INCLUDE_DIRECTORIES GENERATOR_EXPRESSION)
    idf_build_get_property(compile_options COMPILE_OPTIONS GENERATOR_EXPRESSION)
    idf_build_get_property(c_compile_options C_COMPILE_OPTIONS GENERATOR_EXPRESSION)
    idf_build_get_property(cxx_compile_options CXX_COMPILE_OPTIONS GENERATOR_EXPRESSION)
    idf_build_get_property(asm_compile_options ASM_COMPILE_OPTIONS GENERATOR_EXPRESSION)
    idf_build_get_property(common_reqs __COMPONENT_REQUIRES_COMMON)

    include_directories("${include_directories}")
    add_compile_options("${compile_options}")
    add_c_compile_options("${c_compile_options}")
    add_cxx_compile_options("${cxx_compile_options}")
    add_asm_compile_options("${asm_compile_options}")

    # Unfortunately add_definitions() does not support generator expressions. A new command
    # add_compile_definition() does but is only available on CMake 3.12 or newer. This uses
    # add_compile_options(), which can add any option as the workaround.
    #
    # TODO: Use add_compile_definitions() once minimum supported version is 3.12 or newer.
    idf_build_get_property(compile_definitions COMPILE_DEFINITIONS GENERATOR_EXPRESSION)
    add_compile_options("${compile_definitions}")

    if(common_reqs) # check whether common_reqs exists, this may be the case in minimalistic host unit test builds
        # set the component library 
        foreach(comp_lib ${common_reqs})
            __component_get_target(component_target ${comp_lib})
            __component_get_property(lib ${component_target} COMPONENT_LIB)
            list(APPEND common_comps_lib ${lib})     
        endforeach()
            
        list(REMOVE_ITEM common_comps_lib ${component_lib})
        link_libraries(${common_comps_lib})
    endif()

    idf_build_get_property(config_dir CONFIG_DIR)

    # The contents of 'sources' is from the __component_add_sources call
    if(sources OR __EMBED_FILES OR __EMBED_TXTFILES)
        add_library(${component_lib} STATIC ${sources})
        __component_set_property(${component_target} COMPONENT_TYPE LIBRARY)
        __component_add_include_dirs(${component_lib} "${__INCLUDE_DIRS}" PUBLIC)
        __component_add_include_dirs(${component_lib} "${__PRIV_INCLUDE_DIRS}" PRIVATE)
        __component_add_include_dirs(${component_lib} "${config_dir}" PUBLIC)
        set_target_properties(${component_lib} PROPERTIES OUTPUT_NAME ${COMPONENT_NAME} LINKER_LANGUAGE C)
        __ldgen_add_component(${component_lib})
    else()
        add_library(${component_lib} INTERFACE)
        __component_set_property(${component_target} COMPONENT_TYPE CONFIG_ONLY)
        __component_add_include_dirs(${component_lib} "${__INCLUDE_DIRS}" INTERFACE)
        __component_add_include_dirs(${component_lib} "${config_dir}" INTERFACE)
    endif()

    # Alias the static/interface library created for linking to external targets.
    # The alias is the <prefix>::<component name> name.
    __component_get_property(component_alias ${component_target} COMPONENT_ALIAS)
    add_library(${component_alias} ALIAS ${component_lib})

    # Perform other component processing, such as embedding binaries and processing linker
    # script fragments
    foreach(file ${__EMBED_FILES})
        target_add_binary_data(${component_lib} "${file}" "BINARY")
    endforeach()

    foreach(file ${__EMBED_TXTFILES})
        target_add_binary_data(${component_lib} "${file}" "TEXT")
    endforeach()

    if(__LDFRAGMENTS)
        __ldgen_add_fragment_files("${__LDFRAGMENTS}")
    endif()

    # Set dependencies
    __component_set_all_dependencies()

    # Make the COMPONENT_LIB variable available in the component CMakeLists.txt
    set(COMPONENT_LIB ${component_lib} PARENT_SCOPE)
    # COMPONENT_TARGET is deprecated but is made available with same function
    # as COMPONENT_LIB for compatibility.
    set(COMPONENT_TARGET ${component_lib} PARENT_SCOPE)

    __component_set_properties()

endfunction()



# __component_set_dependencies, __component_set_all_dependencies
#
#  Links public and private requirements for the currently processed component
macro(__component_set_dependencies reqs type)
    foreach(req ${reqs})
        if(req IN_LIST build_component_targets)
            __component_get_property(req_lib ${req} COMPONENT_LIB)
            if("${type}" STREQUAL "PRIVATE")
                set_property(TARGET ${component_lib} APPEND PROPERTY LINK_LIBRARIES ${req_lib})
                set_property(TARGET ${component_lib} APPEND PROPERTY INTERFACE_LINK_LIBRARIES $<LINK_ONLY:${req_lib}>)
            elseif("${type}" STREQUAL "PUBLIC")
                set_property(TARGET ${component_lib} APPEND PROPERTY LINK_LIBRARIES ${req_lib})
                set_property(TARGET ${component_lib} APPEND PROPERTY INTERFACE_LINK_LIBRARIES ${req_lib})
            else() # INTERFACE
                set_property(TARGET ${component_lib} APPEND PROPERTY INTERFACE_LINK_LIBRARIES ${req_lib})
            endif()
        endif()
    endforeach()
endmacro()

macro(__component_set_all_dependencies)
    __component_get_property(type ${component_target} COMPONENT_TYPE)
    idf_build_get_property(build_component_targets __BUILD_COMPONENT_TARGETS)

    if(NOT type STREQUAL CONFIG_ONLY)
        __component_get_property(reqs ${component_target} __REQUIRES)
        __component_set_dependencies("${reqs}" PUBLIC)

        __component_get_property(priv_reqs ${component_target} __PRIV_REQUIRES)
        __component_set_dependencies("${priv_reqs}" PRIVATE)
    else()
        __component_get_property(reqs ${component_target} __REQUIRES)
        __component_set_dependencies("${reqs}" INTERFACE)
    endif()
endmacro()


# __component_add_sources, __component_check_target, __component_add_include_dirs
#
# Utility macros for component registration. Adds source files and checks target requirements,
# and adds include directories respectively.
macro(__component_add_sources sources)
    set(sources "")
    if(__SRCS)
        if(__SRC_DIRS)
            message(WARNING "SRCS and SRC_DIRS are both specified; ignoring SRC_DIRS.")
        endif()
        foreach(src ${__SRCS})
            get_filename_component(src "${src}" ABSOLUTE BASE_DIR ${COMPONENT_DIR})
            list(APPEND sources ${src})
        endforeach()
    else()
        if(__SRC_DIRS)
            foreach(dir ${__SRC_DIRS})
                get_filename_component(abs_dir ${dir} ABSOLUTE BASE_DIR ${COMPONENT_DIR})

                if(NOT IS_DIRECTORY ${abs_dir})
                    message(FATAL_ERROR "SRC_DIRS entry '${dir}' does not exist.")
                endif()

                file(GLOB dir_sources "${abs_dir}/*.c" "${abs_dir}/*.cpp" "${abs_dir}/*.S")
                list(SORT dir_sources)

                if(dir_sources)
                    foreach(src ${dir_sources})
                        get_filename_component(src "${src}" ABSOLUTE BASE_DIR ${COMPONENT_DIR})
                        list(APPEND sources "${src}")
                    endforeach()
                else()
                    message(WARNING "No source files found for SRC_DIRS entry '${dir}'.")
                endif()
            endforeach()
        endif()

        if(__EXCLUDE_SRCS)
            foreach(src ${__EXCLUDE_SRCS})
                get_filename_component(src "${src}" ABSOLUTE)
                list(REMOVE_ITEM sources "${src}")
            endforeach()
        endif()
    endif()

    list(REMOVE_DUPLICATES sources)
endmacro()

macro(__component_add_include_dirs lib dirs type)
    foreach(dir ${dirs})
        get_filename_component(_dir ${dir} ABSOLUTE BASE_DIR ${CMAKE_CURRENT_LIST_DIR})
        if(NOT IS_DIRECTORY ${_dir})
            message(FATAL_ERROR "Include directory '${_dir}' is not a directory.")
        endif()
        target_include_directories(${lib} ${type} ${_dir})
    endforeach()
endmacro()


macro(__component_check_target)
    if(__REQUIRED_IDF_TARGETS)
        idf_build_get_property(idf_target IDF_TARGET)
        if(NOT idf_target IN_LIST __REQUIRED_IDF_TARGETS)
            message(FATAL_ERROR "Component ${COMPONENT_NAME} only supports targets: ${__REQUIRED_IDF_TARGETS}")
        endif()
    endif()
endmacro()



macro(__component_set_properties)
    __component_get_property(type ${component_target} COMPONENT_TYPE)

    # Fill in the rest of component property
    __component_set_property(${component_target} SRCS "${sources}")
    __component_set_property(${component_target} INCLUDE_DIRS "${__INCLUDE_DIRS}")

    if(type STREQUAL LIBRARY)
        __component_set_property(${component_target} PRIV_INCLUDE_DIRS "${__PRIV_INCLUDE_DIRS}")
    endif()

    __component_set_property(${component_target} LDFRAGMENTS "${__LDFRAGMENTS}")
    __component_set_property(${component_target} EMBED_FILES "${__EMBED_FILES}")
    __component_set_property(${component_target} EMBED_TXTFILES "${__EMBED_TXTFILES}")
    __component_set_property(${component_target} REQUIRED_IDF_TARGETS "${__REQUIRED_IDF_TARGETS}")

    __component_set_property(${component_target} WHOLE_ARCHIVE ${__WHOLE_ARCHIVE})
endmacro()

# idf_component_optional_requires
#
# @brief Add a dependency on a given component only if it is included in the build.
# 
# only add the dependency of INTERFACE target to it to add the include dirs 
# @param[in]  type of the dependency, one of: PRIVATE, PUBLIC, INTERFACE
# @param[in, multivalue] list of component names which should be added as dependencies
#

function(idf_component_optional_requires req_type)
    set(optional_reqs ${ARGN})
    idf_build_get_property(build_components BUILD_COMPONENTS)
    foreach(req ${optional_reqs})
    list(FIND build_components ${req} res)
        if(NOT res EQUAL -1)
            idf_component_get_property(req_lib ${req} COMPONENT_LIB)
            target_link_libraries(${COMPONENT_LIB} ${req_type} ${req_lib})
        endif()
    endforeach()
endfunction()

# add link dependency to the target 
function(idf_component_add_link_dependency)
    set(single_value FROM TO)
    cmake_parse_arguments(_ "" "${single_value}" "" ${ARGN})

    idf_component_get_property(from_lib ${__FROM} COMPONENT_LIB)
    if(__TO)
        idf_component_get_property(to_lib ${__TO} COMPONENT_LIB)
    else()
        set(to_lib ${COMPONENT_LIB})
    endif()
    set_property(TARGET ${from_lib} APPEND PROPERTY INTERFACE_LINK_LIBRARIES $<LINK_ONLY:${to_lib}>)
endfunction()

