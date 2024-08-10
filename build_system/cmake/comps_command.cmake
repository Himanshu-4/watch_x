################################################################################
# comps_command.cmake
# Description:
#   	component command that will build the component  file.
#
# Notes:
#       Please dont modify existing CMAKE function and commands unless highly required 
# 		 Additional notes
#
################################################################################
# [Contents of the file below]
# check for minimum cmake version to run this script
cmake_minimum_required(VERSION 3.2.1)

# set the cmake policy to new 

cmake_policy(SET CMP0057 NEW)

# idf_component_get_property
#
# @brief Retrieve the value of the specified component property
#
# @param[out] var the variable to store the value of the property in
# @param[in] component the component name or alias to get the value of the property of
# @param[in] property the property to get the value of
#
# @param[in, optional] GENERATOR_EXPRESSION (option) retrieve the generator expression for the property
#                   instead of actual value
function(idf_component_get_property var component property)
    cmake_parse_arguments(_ "GENERATOR_EXPRESSION" "" "" ${ARGN})
    __component_get_target(component_target ${component})
    if(__GENERATOR_EXPRESSION)
        set(val "$<TARGET_PROPERTY:${component_target},${property}>")
    else()
        __component_get_property(val ${component_target} ${property})
    endif()
    set(${var} "${val}" PARENT_SCOPE)
endfunction()


# idf_component_set_property
#
# @brief Set the value of the specified component property related. The property is
#        also added to the internal list of component properties if it isn't there already.
#
# @param[in] component component name or alias of the component to set the property of
# @param[in] property the property to set the value of
# @param[out] value value of the property to set to
#
# @param[in, optional] APPEND (option) append the value to the current value of the
#                     property instead of replacing it
function(idf_component_set_property component property val)
    cmake_parse_arguments(_ "APPEND" "" "" ${ARGN})
    __component_get_target(component_target ${component})

    if(__APPEND)
        __component_set_property(${component_target} ${property} "${val}" APPEND)
    else()
        __component_set_property(${component_target} ${property} "${val}")
    endif()
endfunction()

# @name component_get_property 
#   
# @param0  var 
# @param1  component_target 
# @param2  property
# @note    used to get the property of the component_target, must get the target 
#  name from the component_name first then specify here    
# @usage   used to get target property of components 
# @scope  anywhere
# scope tells where should this cmake function used 
# 
function(__component_get_property var component_target property)
    cmake_parse_arguments(_ "GENERATOR_EXPRESSION" "" "" ${ARGN})
    if(__GENERATOR_EXPRESSION)
        set(val "$<TARGET_PROPERTY:${component_target},${property}>")
    else()
        get_property(val TARGET ${component_target} PROPERTY ${property})
    endif()
    set(${var} ${val} PARENT_SCOPE)
endfunction()

# @name component_set_property 
#   
# @param0  component_target 
# @param1  property
# @param2  val 
# @note    used to set the property of the component_target, must get the target 
#  name from the component_name first then specify here    
# @usage   used to set target property of components 
# @scope  anywhere
# scope tells where should this cmake function used 
# 
function(__component_set_property component_target property val)
    cmake_parse_arguments(_ "APPEND" "" "" ${ARGN})

    if(__APPEND)
        set_property(TARGET ${component_target} APPEND PROPERTY ${property} "${val}")
    else()
        set_property(TARGET ${component_target} PROPERTY ${property} "${val}")
    endif()

    # Keep track of set component properties this will contian all the properties set 
    # by the different components 
    __component_get_property(properties ${component_target} __COMPONENT_PROPERTIES)
    if(NOT property IN_LIST properties)
        __component_set_property(${component_target} __COMPONENT_PROPERTIES ${property} APPEND)
    endif()
endfunction()

# @name component_get_target 
#   
# @param0  component_name component_name)  
# @param1  target_name
# @note    used to get the target name can be 1 or more than 1 
#           (there can be multiple targets name from component name
#           like __${component_name}_main_target  __${component_name}_priv_target )
# @usage   usage  
# @scope  scope   
# scope tells where should this cmake function used 
# 
function(__component_get_target target_out name_or_alias)
    # we know that the name could match one of the following thing 
    
    idf_build_get_property(component_targets __COMPONENT_TARGETS)
    idf_build_get_property(prefix __PREFIX)
    # check if the name is present in the component_targets
    
    # string(REGEX REPLACE ".*${prefix}[_:]*([a-zA-Z_]+)$" "\\1" component_name ${name_or_alias})    
    string(REGEX REPLACE "^(.*_)*idf_?(::)?([^_]+)([_-]?.*)?$" "\\3\\4" component_name ${name_or_alias})
    
    set(component_target ___${prefix}_${component_name})
 
    # if target not found in __COMPONENT_TARGETS , show warning 
    if (NOT ${component_target} IN_LIST component_targets)
        # show the warning to the user 
        message(FATAL_ERROR "component target ${component_target} is not found in the component_target list")
    endif()

    set(${target_out} ${component_target} PARENT_SCOPE)

    # # # List of input strings
    # set(input_strings "___idf_soc;__idf_esp_log;idf_nvs;_idfspi_flash;idf::newlib;idf_bt;esp_system;esp_wifi;esp-tls;lwip;idf::esp-tls, __idf_::esp-tls, __idf_esp-tls")

    # # Loop through each item in the list
    # foreach(item ${input_strings})

    #     # Extract the name using a regular expression that includes idf
    #     # string(REGEX REPLACE ".*${prefix}[_:]*([a-zA-Z_]+)$" "\\1" name "${item}")
    #       # Remove all prefixes like "___idf", "__idf", "_idf", "idf::", "idf"
    #     string(REGEX REPLACE "^(.*_)*idf_?(::)?([^_]+)([_-]?.*)?$" "\\3\\4" cleaned_item "${item}")
    
    #     # Replace "_" with "-" if needed
    #     # string(REGEX REPLACE "_" "-" cleaned_item "${cleaned_item}")
    #     message(STATUS "Extracted name: ${cleaned_item}")
    # endforeach()

    # # exit here 
    # message(FATAL_ERROR "can't proce")
endfunction()


# =====================================================================================================
# =====================================================================================================
# ===========================     Function to scan the all the components present in the component dir 
# this will help us to attach the basic properties to that component without including in the build 

# @name __scan_component 
#   
# @param0  comps_path 
# @note    used to add the components in the build 
# @usage   usage  
# @scope  scope   
# scope tells where should this cmake function used 
# 
function(__scan_components sdk_path prefix)
   
    set(components "")
    get_filename_component(comps_path ${sdk_path} ABSOLUTE)
    if(NOT EXISTS ${comps_path})
        message(FATAL_ERROR "${comps_path} path doesn't valid Path that contain COMPONENTS")
    endif()

    # get all the dir that contains the cmakelists.txt
    file(GLOB  build_comps_dirs "${comps_path}/*/CMakeLists.txt" )

    foreach(comp_dir ${build_comps_dirs})
        get_filename_component(component_dir ${comp_dir} DIRECTORY)
        __add_individual_component("${component_dir}" ${prefix})
    endforeach()

    
    idf_build_get_property(scan SCAN_COMPONENTS)
    message(STATUS "------------------------------scan compoents are below-------------------------------\r\n${scan}\r\n-------------------------------------------------------------------------------------------------------")

    
endfunction()

#
# Add a component to process in the build. The components are keeped tracked of in property
# __COMPONENT_TARGETS in component target form.
#
function(__add_individual_component component_dir prefix)
    # For each component, two entities are created: a component target and a component library. The
    # component library is created during component registration (the actual static/interface library).
    # On the other hand, component targets are created early in the build
    # (during adding component as this function suggests).
    # This is so that we still have a target to attach properties to up until the component registration.
    # Plus, interface libraries have limitations on the types of properties that can be set on them,
    # so later in the build, these component targets actually contain the properties meant for the
    # corresponding component library.
    idf_build_get_property(component_targets __COMPONENT_TARGETS)
    
    get_filename_component(abs_dir ${component_dir} ABSOLUTE)
    get_filename_component(base_dir ${abs_dir} NAME)
    
    set(component_name ${base_dir})
    
    if(NOT EXISTS "${abs_dir}/CMakeLists.txt")
        message(FATAL_ERROR "Directory '${component_dir}' does not contain a component.")
    endif()   

    # The component target has three underscores as a prefix. The corresponding component library
    # only has two.
    set(component_target ___${prefix}_${component_name})
 
    # If a component of the same name has not been added before If it has been added
    # before just override the properties. As a side effect, components added later
    # 'override' components added earlier.
    # if (NOT ${component_target} IN_LIST component_targets) // this creates some isssues 
    list(FIND component_targets ${component_target} res)
    if(res EQUAL -1)
        if(NOT TARGET ${component_target})
            add_library(${component_target} STATIC IMPORTED)
        endif()
        idf_build_set_property(__COMPONENT_TARGETS ${component_target} APPEND)
    else()
        message(WARNING "the compoent target ${component_target} already present in __COMPONENT_TARGET")
        __component_get_property(dir ${component_target} COMPONENT_DIR)
        __component_set_property(${component_target} COMPONENT_OVERRIDEN_DIR ${dir})
    endif()
    
    set(component_lib __${prefix}_${component_name})
    set(component_dir ${abs_dir})
    set(component_alias ${prefix}::${component_name}) # The 'alias' of the component library,
                                                    # used to refer to the component outside
                                                    # the build system. Users can use this name
                                                    # to resolve ambiguity with component names
                                                    # and to link IDF components to external targets.

    # Set the basic properties of the component
    __component_set_property(${component_target} COMPONENT_LIB ${component_lib})
    __component_set_property(${component_target} COMPONENT_NAME ${component_name})
    __component_set_property(${component_target} COMPONENT_DIR ${component_dir})
    __component_set_property(${component_target} COMPONENT_ALIAS ${component_alias})

    __component_set_property(${component_target} __PREFIX ${prefix})

    # init the kconfig files 
    __kconfig_component_init(${component_target})

    # append BUILD_COMPONENT_DIRS build property
    idf_build_set_property(SCAN_COMPONENTS_DIR  ${component_dir} APPEND)
    # add all the scan components in the build property 
    idf_build_set_property(SCAN_COMPONENTS ${component_name} APPEND)
endfunction()


# @name __set_neccessary_compoents 
#   
# @note    add the neccesarry components into the build 
# @usage   usage  
# @scope  scope   
# scope tells where should this cmake function used 
# 
function(__set_neccessary_components comps)
    
    # get the  components and see if they are present in the 
    # scan components 
    idf_build_get_property(all_comps SCAN_COMPONENTS)
    
    foreach(comps ${components})
        # list(FIND all_comps ${comps} res)
        # if(res EQUAL -1)
        if (NOT ${comps} IN_LIST all_comps )
            message(FATAL_ERROR "can't find the ${comps} in the SCAN components \
                        the components is missing ")
        endif()
    endforeach()

    # add the common required components and build components to the path 
    __get_neccessary_components(common_required_components COMMON_REQUIRED)
    
    idf_build_set_property(BUILD_COMPONENTS "${common_required_components}" APPEND)
    
    # get the property ad set the components in the parent scope 
    idf_build_get_property(coms BUILD_COMPONENTS)
    set(${comps} ${coms} PARENT_SCOPE)

endfunction()


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
macro(__include_project_cmake_files  components)
    idf_build_get_property(sdk_path SDK_PATH) 

    # Make each build property available as a read-only variable
    idf_build_get_property(build_properties __BUILD_PROPERTIES)
    foreach(build_property ${build_properties})
        idf_build_get_property(val ${build_property})
        set(${build_property} "${val}")
    endforeach()

    list(SORT components)
    foreach(comp ${components})
        # get the component target 
        __component_get_target(component_target ${comp})
        __component_get_property(dir ${component_target} COMPONENT_DIR)
        __component_get_property(_name ${component_target} COMPONENT_NAME)
        set(COMPONENT_NAME ${_name})
        set(COMPONENT_DIR ${dir})
        set(COMPONENT_PATH ${dir})  # this is deprecated, users are encouraged to use COMPONENT_DIR;
                                    # retained for compatibility
        if(EXISTS ${COMPONENT_DIR}/project_include.cmake)
            # include the project include.cmake file
            message(STATUS "Adding project.cmake file from ${comp}")
            include(${COMPONENT_DIR}/project_include.cmake)
        endif()
    endforeach()
    
endmacro()

# @name __get_neccessary_components 
#   
# @param0  components   
# @note    used to get the neccessary components 
# @usage   used to get the neccesary component for the build these components are 
#           required for the build system
# @scope    any cmake file
# scope tells where should this cmake function used 
# 
function(__get_neccessary_components components)
    set(option COMMON_REQUIRED)
    cmake_parse_arguments(_ "${option}" "" "" ${ARGN})

    # common requierd components that should be linked to all the targets
    set(common_req_comps 
            cxx newlib freertos esp_hw_support
            heap log soc hal
            esp_rom esp_common esp_system
    )

    if(BOOTLOADER_BUILD)
        # get the bootloader components from the idf build 
        idf_build_get_property(bootloader_comps BOOTLOADER_COMPONENTS)
        set(${components} ${bootloader_comps} PARENT_SCOPE)
        return()
    endif()

    if(__COMMON_REQUIRED)
        # provide these common reqquired components  to the user 
        set(${components} ${common_req_comps} PARENT_SCOPE)
    else()
        # provide these components to the user 
        set(${components} ${build_comps} PARENT_SCOPE)
    endif()
endfunction()


# @name target_add_bin_data 
#   
# @param0  target 
# @param1  embed_file 
# @param2  embed_type
# @note       Add binary data into the build target by converting it into a source file compile it as part of the build
# @usage   to add custom files to build like txt files 
# @scope  parent_scope
# scope tells where should this cmake function used 
# 
function(target_add_binary_data target embed_file embed_type)
    cmake_parse_arguments(_ "" "RENAME_TO" "DEPENDS" ${ARGN})

    #  if this have depends then it would be in this var __DEPENDS
    get_property(build_dir TARGET ${target} PROPERTY BINARY_DIR)

    get_filename_component(embed_file "${embed_file}" ABSOLUTE)

    get_filename_component(name "${embed_file}" NAME)
    set(embed_srcfile "${build_dir}/${name}.S")

    set(rename_to_arg)
    if(__RENAME_TO)  # use a predefined variable name
        set(rename_to_arg -D "VARIABLE_BASENAME=${__RENAME_TO}")
    endif()

    idf_build_get_property(idf_path IDF_PATH)

    add_custom_command(OUTPUT "${embed_srcfile}"
        COMMAND "${CMAKE_COMMAND}"
        -D "DATA_FILE=${embed_file}"
        -D "SOURCE_FILE=${embed_srcfile}"
        ${rename_to_arg}
        -D "FILE_TYPE=${embed_type}"
        -P "${idf_path}/tools/cmake/scripts/data_file_embed_asm.cmake"
        MAIN_DEPENDENCY "${embed_file}"
        DEPENDS "${idf_path}/tools/cmake/scripts/data_file_embed_asm.cmake" ${__DEPENDS}
        WORKING_DIRECTORY "${build_dir}"
        VERBATIM)

    set_property(DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}" APPEND PROPERTY ADDITIONAL_CLEAN_FILES "${embed_srcfile}")

    # add the source files to the target 
    target_sources("${target}" PRIVATE "${embed_srcfile}")
endfunction()

