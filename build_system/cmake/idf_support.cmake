################################################################################
# idf_support.cmake
#
# Description:
#   	this file contains the idf commands used to build a component target or the 
#       whole project .
#
# Notes:
#       Please dont modify existing CMAKE function and commands unless highly required 
# 		 Additional notes
#
################################################################################
# [Contents of the file below]
# check for minimum cmake version to run this script
cmake_minimum_required(VERSION 3.2.1)

cmake_policy(SET CMP0057 NEW)

# include the components.cmake file into the build 
include(comps)


# ========================================================================================================
# ========================================================================================================
# ========================================================================================================
# ============= there are certain important stuff that need to be taken into account =====================
# ====== BUILD_COMPONENT PROPERTY in TARGET scope that need to be resolved in order for 
# the idf_build_process_Start 
# ========================================================================================================
# ========================================================================================================
# ========================================================================================================
# ========================================================================================================



# @name idf_generate_sdkconfig 
#    
# @note    This function will fetch all the components from the build    
# @usage   usage  
# @scope  scope   
# scope tells where should this cmake function used 
# 
macro(idf_generate_and_add_sdkconfig)
    
    # find the components that we have to include  in the build 
    idf_build_get_property(sdk_path SDK_PATH)
    idf_build_get_property(build_dir BUILD_DIR)

    idf_build_get_property(prefix __PREFIX)
    if (NOT prefix)
        message(FATAL_ERROR "the prefix is not defined in property ")
    endif()

    # scan all the components in the component directory 
    # and make their component target so menuconfig can find kconfig files 
    __scan_components( ${sdk_path} ${prefix})
     

    # set the neccesaary components 
    __set_neccessary_components(build_components)

    # show the build components 
    message(STATUS "build components are ${build_components}")
    
    # now add the build components to the kconfig generator 
    # generate the sdkconfigs from gathers kconfigs*
    if(NOT BOOTLOADER_BUILD)
        # we are not generating sdkconfig files when building bootloader
        message(STATUS "=================== start generating kconfig files and processing components =============================")
        kconfig_generate_config("${build_components}" GENERATE_SDKCONFIG)
        
    endif()

    # check if config directorty is defined in the cmake arguments 
    if(CONFIG_DIR)
        set(config_dir ${CONFIG_DIR})

    else()
        set(config_dir "${build_dir}/config")
    endif()

    find_file(sdkconfig_cmake "sdkconfig.cmake"
                HINTS  "${config_dir}"
                NO_CACHE
                NO_CMAKE_FIND_ROOT_PATH
                )

    if(sdkconfig_cmake)
        message(STATUS "Adding the  ${sdkconfig_cmake} file to the build ")
        get_filename_component(sdkconfig_cmake_file "${sdkconfig_cmake}" ABSOLUTE)
        include(${sdkconfig_cmake_file})
    else()
        message(STATUS "searching for sdkconfig cmake in ${config_dir}")
        message(FATAL_ERROR "Failed to find sdkconfig.cmake file")
    endif()

endmacro()

# @name idf_include_components
#   
# @note    used to build the s components that idf found in build_compos path and 
#           that are required for by the project, otherwise unneccessary components 
#           don't get included in the build, this only includes the component
# @usage   usage  
# @scope  scope   
# scope tells where should this cmake function used 
# 
macro(idf_include_components)

    idf_build_get_property(build_comps BUILD_COMPONENTS)
    __include_project_cmake_files("${build_comps}")
endmacro()


# @name idf_build_process_start 
#   
#  @param end_target
# @note    this will actually start the build process 
#           process the kconfig and genrate sdkconfig files    
# @usage   should be used at the end of main cmake file 
# @scope  root file    
# scope tells where should this cmake function used 
# 
macro(idf_build_process_init )
    
    # Generate compile_commands.json (needs to come after project call).
    set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

    # __show_build_component(${end_target})
    # start the build process for the components 
    __idf_build_start_process()
    
endmacro()



# @name __idf_build_start_process 
#   
# @note    used to start the build process ,    
# @usage   used in the macro idf_build_start_process
# @scope  this file only    
# scope tells where should this cmake function used 
# 
function(__idf_build_start_process)
 
    idf_build_get_property(build_dir BUILD_DIR)

    set(comps_build_dir "${build_dir}/components")

    idf_build_get_property(build_comps BUILD_COMPONENTS)
    list(REMOVE_DUPLICATES build_comps)
    
    idf_build_get_property(prefix __PREFIX)
    # Add each component as a subdirectory, processing each component's CMakeLists.txt
    foreach(component ${build_comps})
        # get the component target from component 
        __component_get_target(component_target ${component})
        __component_get_property(dir ${component_target} COMPONENT_DIR)
        __component_get_property(_name ${component_target} COMPONENT_NAME)
        __component_get_property(alias ${component_target} COMPONENT_ALIAS)
        set(COMPONENT_NAME ${_name})
        set(COMPONENT_DIR ${dir})
        set(COMPONENT_PATH ${dir}) # for backward compatibility only, COMPONENT_DIR is preferred
        set(COMPONENT_ALIAS ${alias})
        set(__idf_component_context 1)
        message(STATUS "adding component ${_name}")
        add_subdirectory(${dir} "${comps_build_dir}/${_name}")
        set(__idf_component_context 0)
    endforeach()


    #  the test_compoenets is empty 
    # __project_info("${test_components}")
    idf_build_get_property(props __BUILD_PROPERTIES)
    message(STATUS "build properties are ${props}")
    
    idf_build_get_property(ldgen __LDGEN_LIBRARIES)
    message(STATUS "ldgen files are ${ldgen}")

endfunction()



# this will also append the TARGET BUILD_COMPONENTS property, so that we are known with all the build components
# @name idf_build_Executable 
#
# @param0 executable_name --> name of the executbale to be build 
# @param1 executable_bin_path for the project 
# @brief link the executable to only the specific components that are required 
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
function(idf_build_executable executable_name  executable_bin_path)
    # paarse the arguments 
    set(options WHOLE_ARCHIVE EXCLUDE_ALL)
    set(single_value KCONFIG KCONFIG_PROJBUILD)
    set(multi_value SRCS SRC_DIRS EXCLUDE_SRCS
                    INCLUDE_DIRS REQUIRES LDFRAGMENTS 
                    LINK_LIBS  LINK_MULTIPLICITY  EXCLUDE_COMPS)
                
    cmake_parse_arguments(_ "${options}" "${single_value}" "${multi_value}" ${ARGN})
    
    # collect all the sources in the src variable 
    __component_add_sources(sources)

    # generate the target as executable name 
    set(exec ${executable_name})
    
    if(__EXCLUDE_ALL)
        add_executable(${exec} EXCLUDE_FROM_ALL ${sources})
    else()
        add_executable(${exec} ${sources})
    endif()
    # include the component includes headers 
    # there would be no private libraries as it is the target where all libs 
    # are linked to  
    __component_add_include_dirs(${exec}  PUBLIC  "${__INCLUDE_DIRS}")
    
      # Use generator expression so that users can append/override flags even after call to
    # idf_build_process
    # idf_build_get_property(include_directories INCLUDE_DIRECTORIES GENERATOR_EXPRESSION)
    idf_build_get_property(compile_options COMPILE_OPTIONS )
    idf_build_get_property(compile_definitions COMPILE_DEFINITIONS)
    idf_build_get_property(c_compile_options C_COMPILE_OPTIONS )
    idf_build_get_property(cxx_compile_options CXX_COMPILE_OPTIONS)
    idf_build_get_property(asm_compile_options ASM_COMPILE_OPTIONS)
    
    idf_build_get_property(common_reqs COMMON_REQUIRED_COMPONENT)
    
    idf_build_get_property(config_dir CONFIG_DIR)
    
    # add_compile_options("${compile_options}")
    # add_compile_definitions("${compile_definitions}")
    # add_c_compile_options("${c_compile_options}")
    # add_cxx_compile_options("${cxx_compile_options}")
    # add_asm_compile_options("${asm_compile_options}")

    target_compile_options(${exec}  PRIVATE $<$<COMPILE_LANGUAGE:C>:${c_compile_options}>)
    target_compile_options(${exec}  PRIVATE $<$<COMPILE_LANGUAGE:CXX>:${cxx_compile_options}>)
    target_compile_options(${exec}  PRIVATE $<$<COMPILE_LANGUAGE:ASM>:${asm_compile_options}>)
    
    target_compile_definitions(${exec}  PRIVATE ${compile_definitions})

    set_target_properties(${exec} PROPERTIES 
                OUTPUT_NAME ${exec}
                LINKER_LANGUAGE C
                )
    # check if common requires exist these components are minimilstic requirements of other comps 
    if(common_reqs) 
    # link the components
      foreach(target ${common_reqs})
          # link the target to this compoent 
          __component_get_target(target_name ${target})
          target_link_libraries(${exec}  PUBLIC ${target_name})
      endforeach()    
    endif()

    if(__REQUIRES)
        foreach(req ${__REQUIRES} )
            # it actually populates the target property but has only INTERFACE PROPERTY 
            __component_get_target(target_name ${req})
            target_link_libraries(${exec} PUBLIC ${target_name})    
        endforeach()
    endif()

    target_include_directories(${exec} PUBLIC ${config_dir})

    # add the link fragments to the target  
    if(__LDFRAGMENTS)
        __ldgen_add_fragment_files("${__LDFRAGMENTS}")
    endif()

    if(__LINK_LIBS)
        set(LINK_LIBS "LINK_LIBS" "${__LINK_LIBS}")
    else()
        set(LINK_LIBS "")
    endif()

    if(__LINK_MULTIPLICITY)
        set(LINK_MULTIPLICITY "LINK_MULTIPLICITY" "${__LINK_MULTIPLICITY}")
    else()
        set(LINK_MULTIPLICITY "")
    endif()

    # exclude comps specified to not link against it 
    if(__EXCLUDE_COMPS)
        set(EXCLUDE_COMPS "EXCLUDE_COMPS" "${__EXCLUDE_COMPS}")
    else()
        set(EXCLUDE_COMPS "")
    endif()

    # set the link time dependecy for the files 
    idf_link_executable(${executable_name}  ${executable_bin_path} ${LINK_LIBS} ${LINK_MULTIPLICITY} ${EXCLUDE_COMPS})

    add_dependencies(${executable_name}  __idf_build_target)
    # there might have to generate a flash target or mergebins target 
    # get the project target

    # set the suffix to .elf for the executable 
    set_property(TARGET ${executable_name}  PROPERTY SUFFIX .elf)
endfunction()

# @name idf_process_linker 
#    
# @note    collect all the linker files (.lf) from the different targets that were build
#           convert all them .ld files and pass to linker while linking
# @usage   usage  
# @scope  scope   
# scope tells where should this cmake function used 
# 
function(idf_link_executable  executable executable_bin_path)
    # paarse the arguments 
    set(options "")
    set(single_value "")
    set(multi_value LINK_LIBS LINK_MULTIPLICITY EXCLUDE_COMPS)

    # get the prefix 
    idf_build_get_property(prefix __PREFIX)
                
    cmake_parse_arguments(_ "${options}" "${single_value}" "${multi_value}" ${ARGN})
    
    
    # Join all the component in final link component list 
    idf_build_get_property(build_comps BUILD_COMPONENTS )
    if(__LINK_LIBS)
        list(APPEND build_comps  ${__LINK_LIBS} )
    endif()

    set(link_multiplicity_libs ${__LINK_MULTIPLICITY})
    set(exclude_comps ${__EXCLUDE_COMPS})

    # link all the libraries 
    foreach(comp ${build_comps})
        # get the target from the raw input name and then get its component lib
        __component_get_target(component_target ${comp})
        __component_get_property(component_lib ${component_target} COMPONENT_LIB)
        
        # if we have exclude component list then exclude from the link components
        if(exclude_comps)
            list(FIND exclude_comps ${comp} res)
            if(NOT res EQUAL -1)
                message(STATUS "Removinng ${comp} from the link target ${executable}")
                continue()
            endif()
        endif()

        if(link_multiplicity_libs)
            # check if we have to increase the link multiplicity of that library 
            list(FIND link_multiplicity_libs ${comp} res)
            if(NOT res EQUAL -1)
                message(STATUS "increasing link muliplicity for the library ${comp}")
                # increase the link muliplicity of the component library  doesn't work @todo
                set_property(TARGET ${component_lib} APPEND PROPERTY LINK_INTERFACE_MULTIPLICITY 6) 
            endif()
        endif()

        target_link_libraries(${executable} PUBLIC ${component_lib})
    endforeach()
    
  
    # find the executable name directory this must be present in the binary dir 
    if(NOT EXISTS ${executable_bin_path})
        message(FATAL_ERROR "${executable_bin_path} path doesn't exist 
                    for the executable ${executable}")
    endif()

    # set the map file for the target executable 
    set(mapfile "${executable_bin_path}/${executable}.map")
    set(idf_target "${IDF_TARGET}")
    
    string(TOUPPER ${idf_target} idf_target)
    # Add cross-reference table to the map file

    target_link_options(${executable} PUBLIC 
                                            "-mlongcalls"    
                                            "-Wl,--cref"
                                            "-Wno-frame-address"
                                            # dump garbage collect sections 
                                            "-Wl,--gc-sections"
                                            "-Wl,--warn-common"
                                            "-fno-rtti" "-fno-lto"
                                            )
    # Add this symbol as a hint for esp_idf_size to guess the target name
    target_link_options(${executable} PUBLIC "-Wl,--defsym=IDF_TARGET_${idf_target}=0")
    # Enable map file output
    target_link_options(${executable} PUBLIC "-Wl,--Map=${mapfile}" 
                                # "-Wl,--print-gc-sections"
                                "-Wl,--check-sections"
                                "-Wl,--print-memory-usage"
                                )

    # target_link_libraries(${executable} PUBLIC m stdc++)

    # Check if linker supports --no-warn-rwx-segments
    execute_process(COMMAND ${CMAKE_LINKER} "--no-warn-rwx-segments" "--version"
        RESULT_VARIABLE result
        OUTPUT_QUIET
        ERROR_QUIET)
    if(${result} EQUAL 0)
        # Do not print RWX segment warnings
        target_link_options(${executable} PUBLIC "-Wl,--no-warn-rwx-segments")
    endif()
    unset(idf_target)


    set_property(DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}" APPEND PROPERTY
    ADDITIONAL_CLEAN_FILES
    "${mapfile}")
endfunction()

# @name specify_path 
#   
# @param0  path_type 
# @param1  path_value 
# @note    used to specify the property path_type value like the path 
# @usage   usage  
# @scope  scope   
# scope tells where should this cmake function used 
# 
function(specify_path path_type path_value)
    idf_build_set_property(${path_type} ${path_value})
endfunction()


# @name idf_add_custom_targets   
#   
# @note    this will add the custom target to the project related to size    
# @usage   usage  
# @scope  scope   
# scope tells where should this cmake function used 
# 
function(idf_add_custom_targets)
    message(STATUS "adding custom targets to the project")

    # in the reconfigure command the delete will delete the cmake cache file
    add_custom_target(reconfigure
                        COMMAND del  CMakeCache.txt
                        COMMENT "to re run the cmake from scratch"
                        WORKING_DIRECTORY ${CMAKE_BINARY_DIR}                        
                        )

    idf_build_get_property(cmake_scripts_path CMAKE_SCRIPTS_PATH)
    idf_build_get_property(python  PYTHON)

    set(idf_size ${python} -m esp_idf_size)

    # Add size targets, depend on map file, run esp_idf_size
    # OUTPUT_JSON is passed for compatibility reasons, SIZE_OUTPUT_FORMAT
    # environment variable is recommended and has higher priority
    add_custom_target(size
                COMMAND ${CMAKE_COMMAND}
                -D "IDF_SIZE_TOOL=${idf_size}"
                -D "MAP_FILE=${mapfile}"
                -D "OUTPUT_JSON=${OUTPUT_JSON}"
                -P "${cmake_scripts_path}/tools/run_size_tool.cmake"
                DEPENDS ${mapfile}
                USES_TERMINAL
                VERBATIM
                )

    add_custom_target(size-files
                    COMMAND ${CMAKE_COMMAND}
                    -D "IDF_SIZE_TOOL=${idf_size}"
                    -D "IDF_SIZE_MODE=--files"
                    -D "MAP_FILE=${mapfile}"
                    -D "OUTPUT_JSON=${OUTPUT_JSON}"
                    -P "${cmake_scripts_path}/tools/run_size_tool.cmake"
                    DEPENDS ${mapfile}
                    USES_TERMINAL
                    VERBATIM
                    )

    add_custom_target(size-components
                    COMMAND ${CMAKE_COMMAND}
                    -D "IDF_SIZE_TOOL=${idf_size}"
                    -D "IDF_SIZE_MODE=--archives"
                    -D "MAP_FILE=${mapfile}"
                    -D "OUTPUT_JSON=${OUTPUT_JSON}"
                    -P "${cmake_scripts_path}/tools/run_size_tool.cmake"
                    DEPENDS ${mapfile}
                    USES_TERMINAL
                    VERBATIM
                    )

    unset(idf_size)

    # Add DFU build and flash targets
    # __add_dfu_targets()

    # # Add UF2 build targets
    # __add_uf2_targets()
endfunction()
