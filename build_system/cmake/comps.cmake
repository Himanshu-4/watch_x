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


# @name component_depends_include 
#   
# @param0  components 
# @note    used to include the component (project_include.cmake files )
# @usage   the project_include.cmake files should be included in early expansion of 
#           components as some comps are depend on them like esptoolpy partition_table etc 
#           they have interconnected dependecy that need to be resolved first   
# @scope  scope   
# scope tells where should this cmake function used 
# 
macro(__add_component_includes  components)
    idf_build_get_property(comps_path BUILD_COMPONENTS_PATH )
    foreach(comp ${components})
        set(cmake_file "${comps_path}/${comp}/project_include.cmake")

        if(NOT EXISTS ${cmake_file})
            message(FATAL_ERROR "can't find the cmake file in the ${cmake_file} directpory ")
        endif()

        include(${cmake_file})
    endforeach()
    
endmacro()


# this will also append the TARGET BUILD_COMPONENTS property, so that we are known with all the build components
# @name build_component_register 
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
    
    # paarse the arguments 
    set(options WHOLE_ARCHIVE)
    set(single_value COMP_NAME KCONFIG KCONFIG_PROJBUILD)
    set(multi_value SRCS SRC_DIRS EXCLUDE_SRCS INCLUDE_DIRS PRIV_INCLUDE_DIRS
                    LDFRAGMENTS REQUIRES PRIV_REQUIRES REQUIRED_IDF_TARGETS
                    EMBED_FILES EMBED_TXTFILES  LINK_TARGETS)
    cmake_parse_arguments(_ "${options}" "${single_value}" "${multi_value}" ${ARGN})
    
    set(component_name "")
    # if component name is present then set this name otherwise search for name 
    if(__COMP_NAME)
        set(component_name ${__COMP_NAME})
    else()
        # serach for the component filename directory 
        get_filename_component(comp_name ${CMAKE_CURRENT_LIST_DIR} NAME)
        set(component_name ${comp_name})
    endif()

    # check if there is a requirement of specific IDF_TARGET
    __component_check_target()
    # add the source files to the component library 
    __component_add_sources(sources)

    # Add component manifest to the list of dependencies
    # set_property(DIRECTORY APPEND PROPERTY CMAKE_CONFIGURE_DEPENDS "${COMPONENT_DIR}/idf_component.yml")
    # get the component target 
    __component_get_target(component_target ${component_name} )

    # attach the include directory property to component target so to attach it to other components
    # when required in the dependecy tree  
    __component_add_include_dirs(${component_target}  INTERFACE "${__INCLUDE_DIRS}" )
   
    __component_get_property(component_lib ${component_target} COMPONENT_LIB)

    # set the properties passed to the function 
    __component_set_properties()

    # Use generator expression so that users can append/override flags even after call to
    # idf_build_process
    idf_build_get_property(include_directories INCLUDE_DIRECTORIES )
    idf_build_get_property(compile_options COMPILE_OPTIONS )
    idf_build_get_property(compile_definitions COMPILE_DEFINITIONS )
    idf_build_get_property(c_compile_options C_COMPILE_OPTIONS )
    idf_build_get_property(cxx_compile_options CXX_COMPILE_OPTIONS )
    idf_build_get_property(asm_compile_options ASM_COMPILE_OPTIONS )
    idf_build_get_property(common_reqs COMMON_REQUIRED_COMPONENT)
    
    idf_build_get_property(config_dir CONFIG_DIR)
    
  
      # The contents of 'sources' is from the __component_add_sources call
    if(sources OR __EMBED_FILES OR __EMBED_TXTFILES)
      add_library(${component_lib} STATIC ${sources})
      __component_set_property(${component_lib} COMPONENT_TYPE LIBRARY)
      __component_add_include_dirs(${component_lib}  PUBLIC "${__INCLUDE_DIRS}" )
      __component_add_include_dirs(${component_lib} PRIVATE "${__PRIV_INCLUDE_DIRS}" )
      __component_add_include_dirs(${component_lib} PUBLIC "${config_dir}")
     
    #  set the property of output name and linker language at the same time 
      set_target_properties(${component_lib} PROPERTIES 
            OUTPUT_NAME ${component_name}
            LINKER_LANGUAGE C
            )
    #   add the component in __LDGEN_LIBRARIES
      __ldgen_add_component(${component_lib})

    else()
      add_library(${component_lib} INTERFACE)
      __component_set_property(${component_lib} COMPONENT_TYPE CONFIG_ONLY)
      __component_add_include_dirs(${component_lib} INTERFACE "${__INCLUDE_DIRS}" )
      __component_add_include_dirs(${component_lib} INTERFACE "${config_dir}" )
    endif()

    # get the component property about its type 
    __component_get_property(type ${component_lib} COMPONENT_TYPE)

    if(${type} STREQUAL LIBRARY)    
        # target_compile_options(${component_lib} PRIVATE ${compile_options}) 
        target_compile_options(${component_lib} PRIVATE $<$<COMPILE_LANGUAGE:C>:${c_compile_options}>)
        target_compile_options(${component_lib} PRIVATE $<$<COMPILE_LANGUAGE:CXX>:${cxx_compile_options}>)
        target_compile_options(${component_lib} PRIVATE $<$<COMPILE_LANGUAGE:ASM>:${asm_compile_options}>)
        
        target_compile_definitions(${component_lib} PRIVATE ${compile_definitions})

    endif()

    # used to refer to the component outside
    # the build system. Users can use this name
    # to resolve ambiguity with component names
    # and to link IDF components to external targets.
    # this will add the component_alias to the global scope so any external can link to it 
    __component_get_property(component_alias ${component_target} COMPONENT_ALIAS)
    add_library(${component_alias} ALIAS ${component_lib})

    if(type STREQUAL LIBRARY)
        # check if common requires exist these components are minimilstic requirements of other comps 
        if(common_reqs) 
            # check if the component present in the common requires 
            list(REMOVE_ITEM common_reqs ${component_name})
            # link the components
            foreach(target ${common_reqs})
                # get the component target (aka INTERFACE lib) from the component name 
                __component_get_target(comp_target ${target})
                # link the target to this compoent 
                target_link_libraries(${component_lib} PRIVATE ${comp_target})
                
                set_property(TARGET ${component_lib} APPEND PROPERTY LINK_LIBRARIES ${comp_target})
                set_property(TARGET ${component_lib} APPEND PROPERTY INTERFACE_LINK_LIBRARIES ${comp_target})
            endforeach()    
        endif()

        __component_set_dependencies("${__REQUIRES}" PUBLIC)
        __component_set_dependencies("${__PRIV_REQUIRES}" PRIVATE)

    else()
        __component_get_property(reqs ${component_target} REQUIRES)
        __component_set_dependencies("${reqs}" INTERFACE)
    endif()

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


    # link the requreis and private requreis 
    if(type STREQUAL LIBRARY)  
        # set the requires and private requires for the component 
        # if(__REQUIRES)
        #     foreach(req ${__REQUIRES} )
        #         # it actually populates the target property but has only INTERFACE PROPERTY 
        #         __component_get_target(target_name ${req})
        #         target_link_libraries(${component_lib} PUBLIC ${target_name})  
        #         target_link_libraries(${component_lib} PUBLIC idf::${req})   

                
        #         # set_property(TARGET ${component_lib} APPEND PROPERTY LINK_LIBRARIES idf::${req})
        #         # set_property(TARGET ${component_lib} APPEND PROPERTY INTERFACE_LINK_LIBRARIES idf::${req})
        #         # set_property(TARGET ${component_lib} APPEND PROPERTY LINK_LIBRARIES ${target_name})
        #         # set_property(TARGET ${component_lib} APPEND PROPERTY INTERFACE_LINK_LIBRARIES ${target_name})
        #     endforeach()
        # endif()

       
    
        # add link target to this component (add private requirements) 
        if(__LINK_TARGETS)
            foreach(target ${__LINK_TARGETS})
                target_link_libraries(${component_lib} PUBLIC ${target})
            endforeach()
            
        endif()
    endif() # LIBRARY

    # set the component name in the parent scope 
    set(COMPONENT_LIB  ${component_lib} PARENT_SCOPE)
  
endfunction()



# @name __component_set_dependencies 
#   
# @param0  requires
# @param1  type
# @note    used to set the dependency    
# @usage   usage  
# @scope  scope   
# scope tells where should this cmake function used 
# # 
macro(__component_set_dependencies components type)
    
    # get the build components 
    idf_build_get_property(build_comps BUILD_COMPONENTS)
    foreach(comp_name ${components})
        # get the component target 
        list(FIND build_comps ${comp_name} res)
        if(NOT res EQUAL -1)
            __component_get_target(component_target ${comp_name} )
            __component_get_property(req_lib ${component_target} COMPONENT_LIB)
            message(STATUS "merging  ${component_target} to  ${component_lib}")  
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

# @name __component_add_include_dirs 
#   
# @param0  lib 
# @param1  dirs list of directories
# @param   type 
# @note    used to include the directory to the target   
# @usage   usage  
# @scope  scope   
# scope tells where should this cmake function used 
# 
macro(__component_add_include_dirs lib type dirs)
    foreach(dir ${dirs})
        get_filename_component(_dir ${dir} ABSOLUTE BASE_DIR ${CMAKE_CURRENT_LIST_DIR})
        if(NOT IS_DIRECTORY ${_dir})
            message(FATAL_ERROR "Include directory '${_dir}' is not a directory.")
        endif()
        target_include_directories(${lib} ${type} ${_dir})
    endforeach()
endmacro()


# @name __component_set_properties 
#    
# @note    set the component properties from the  input parameters  
# @usage   used in include_build_component
# @scope  scope   
# scope tells where should this cmake function used 
# 
macro(__component_set_properties)
    __component_get_property(type ${component_target} COMPONENT_TYPE)

    # Fill in the rest of component property
    __component_set_property(${component_target} SRCS "${sources}")
    __component_set_property(${component_target} INCLUDE_DIRS "${__INCLUDE_DIRS}")

    # add requires and prev_requires component 
    __component_set_property(${component_target} REQUIRES "${__REQUIRES}")
    __component_set_property(${component_target} PRIV_REQUIRES "${__PRIV_REQUIRES}")
    

    if(type STREQUAL LIBRARY)
        __component_set_property(${component_target} PRIV_INCLUDE_DIRS "${__PRIV_INCLUDE_DIRS}")
    endif()

    __component_set_property(${component_target} LDFRAGMENTS "${__LDFRAGMENTS}")
    __component_set_property(${component_target} EMBED_FILES "${__EMBED_FILES}")
    __component_set_property(${component_target} EMBED_TXTFILES "${__EMBED_TXTFILES}")
    __component_set_property(${component_target} REQUIRED_IDF_TARGETS "${__REQUIRED_IDF_TARGETS}")

    # set the whole archieve property to 1 or 0
    __component_set_property(${component_target} WHOLE_ARCHIVE ${__WHOLE_ARCHIVE})
endmacro()


# @name __component_check_target 
#   
# @note    check that if there is a target requirement for the particular idf_component_register
# @usage   idf_compoent_register
# @scope  the above function only 
# scope tells where should this cmake function used 
# 
macro(__component_check_target)
    if(__REQUIRED_IDF_TARGETS)
        idf_build_get_property(idf_target IDF_TARGET)
        list(FIND __REQUIRED_IDF_TARGETS ${idf_target} res)
        if(res EQUAL -1)
            message(FATAL_ERROR "Component ${COMPONENT_NAME} only supports targets: ${__REQUIRED_IDF_TARGETS}")
        endif()
    endif()
endmacro()



# @name __component_add_sources 
#   
# @param0  param0 
# @param1  param1 
# @note    Note   
# @usage   usage  
# @scope  scope   
# scope tells where should this cmake function used 
# 
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
        # .search for the input component in the 
        list(FIND build_components ${req} res)
        if(NOT res EQUAL -1)
            idf_component_get_property(req_lib ${req} COMPONENT_LIB)
            target_link_libraries(${COMPONENT_LIB} ${req_type} ${req_lib})

        else()
            message(WARNING "can't find the ${req} in the build components ")
        endif()
    endforeach()
endfunction()
