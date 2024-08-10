################################################################################
# kconfig.cmake
# Description:
#   	kconfig file that will help in configuration the project 
#       and invoke menuconfig tool.
#
# Notes:
#       Please dont modify existing CMAKE function and commands unless highly required 
# 		 Additional notes
#
################################################################################
# [Contents of the file below]
# check for minimum cmake version to run this script
cmake_minimum_required(VERSION 3.2.1)


# @name Kconfig_init 
#   
# @note    init the kconfig file for the    
# @usage   usage  
# @scope  scope   
# scope tells where should this cmake function used 
# 
function(kconfig_init)

    # we are not initing kconfig in bootloader build 
    if(BOOTLOADER_BUILD)
        # set the config directory for components
        if(CONFIG_DIR)
            idf_build_set_property(CONFIG_DIR ${CONFIG_DIR})
        endif()
        return()
    endif()

    idf_build_get_property(build_dir BUILD_DIR)
    idf_build_get_property(idf_path IDF_PATH)

    # create a kconfig directory 
    file(MAKE_DIRECTORY "${build_dir}/kconfig")
    file(MAKE_DIRECTORY "${build_dir}/config")

    idf_build_set_property( __ROOT_KCONFIG ${idf_path}/Kconfig)
    idf_build_set_property( __ROOT_SDKCONFIG_RENAME  ${idf_path}/sdkconfig.rename)
    idf_build_set_property( __OUTPUT_SDKCONFIG 1)

endfunction()

#
# Initialize Kconfig-related properties for components.
# This function assumes that all basic properties of the components have been
# set prior to calling it.
#
function(__kconfig_component_init component_target)
    __component_get_property(component_dir ${component_target} COMPONENT_DIR)

    idf_build_get_property(idf_target IDF_TARGET)

    file(GLOB kconfig "${component_dir}/Kconfig")
    list(SORT kconfig)
    __component_set_property(${component_target} KCONFIG "${kconfig}")
    file(GLOB kconfig "${component_dir}/Kconfig.projbuild")
    list(SORT kconfig)
    __component_set_property(${component_target} KCONFIG_PROJBUILD "${kconfig}")
    file(GLOB sdkconfig_rename "${component_dir}/sdkconfig.rename")
    file(GLOB sdkconfig_rename_target "${component_dir}/sdkconfig.rename.${idf_target}")

    list(APPEND sdkconfig_rename ${sdkconfig_rename_target})
    list(SORT sdkconfig_rename)
    __component_set_property(${component_target} SDKCONFIG_RENAME "${sdkconfig_rename}")
endfunction()

#
# Add bootloader components Kconfig and Kconfig.projbuild files to BOOTLOADER_KCONFIG
# and BOOTLOADER_KCONFIGS_PROJ properties respectively.
#
function(__kconfig_bootloader_component_add component_dir)
    idf_build_get_property(bootloader_kconfigs BOOTLOADER_KCONFIGS)
    idf_build_get_property(bootloader_kconfigs_proj BOOTLOADER_KCONFIGS_PROJ)

    file(GLOB kconfig "${component_dir}/Kconfig")
    list(SORT kconfig)
    if(EXISTS "${kconfig}" AND NOT IS_DIRECTORY "${kconfig}")
        list(APPEND bootloader_kconfigs "${kconfig}")
    endif()

    file(GLOB kconfig "${component_dir}/Kconfig.projbuild")
    list(SORT kconfig)
    if(EXISTS "${kconfig}" AND NOT IS_DIRECTORY "${kconfig}")
        list(APPEND bootloader_kconfigs_proj "${kconfig}")
    endif()

    idf_build_set_property(BOOTLOADER_KCONFIGS "${bootloader_kconfigs}")
    idf_build_set_property(BOOTLOADER_KCONFIGS_PROJ "${bootloader_kconfigs_proj}")
endfunction()


# @name kconfig_generate_config 
#   
# @note    Note   
# @usage   usage  
# @scope  scope   
# scope tells where should this cmake function used 
# 
function(kconfig_generate_config  build_components)
    # set the options 
    set(option GENERATE_SDKCONFIG)
    # get the GENERATE_SDKCONFIG options 
    cmake_parse_arguments(_ "${option}" "" "" ${ARGN})

    
    # get all the kconfig files from the component targets
    foreach(component_name ${build_components})
        # fetch the target name from the component
        __component_get_target(component_target ${component_name}) 
        __component_get_property(kconfig ${component_target} KCONFIG)
        __component_get_property(kconfig_projbuild ${component_target} KCONFIG_PROJBUILD)
        __component_get_property(sdkconfig_rename ${component_target} SDKCONFIG_RENAME)
        if(kconfig)
            list(APPEND kconfigs ${kconfig})
        endif()
        if(kconfig_projbuild)
            list(APPEND kconfig_projbuilds ${kconfig_projbuild})
        endif()
        if(sdkconfig_rename)
            list(APPEND sdkconfig_renames ${sdkconfig_rename})
        endif()
    
    endforeach()

    # Take into account bootloader components configuration files
    idf_build_get_property(bootloader_kconfigs BOOTLOADER_KCONFIGS)
    idf_build_get_property(bootloader_kconfigs_proj BOOTLOADER_KCONFIGS_PROJ)
    if(bootloader_kconfigs)
        list(APPEND kconfigs "${bootloader_kconfigs}")
    endif()
    if(bootloader_kconfigs_proj)
        list(APPEND kconfig_projbuilds "${bootloader_kconfigs_proj}")
    endif()

    # Store the list version of kconfigs and kconfig_projbuilds
    idf_build_set_property(KCONFIGS "${kconfigs}")
    idf_build_set_property(KCONFIG_PROJBUILDS "${kconfig_projbuilds}")

    idf_build_get_property(idf_target IDF_TARGET)
    idf_build_get_property(idf_path IDF_PATH)
    idf_build_get_property(idf_env_fpga __IDF_ENV_FPGA)

    # get the build dir 
    idf_build_get_property(build_dir BUILD_DIR)
    
    set(kconfig_dir "${build_dir}/kconfig")
    # These are the paths for files which will contain the generated "source" lines for COMPONENT_KCONFIGS and
    # COMPONENT_KCONFIGS_PROJBUILD
    set(kconfigs_projbuild_path "${kconfig_dir}/kconfigs_projbuild.in")
    set(kconfigs_path "${kconfig_dir}/kconfigs.in")

    # Place config-related environment arguments into config.env file
    # to work around command line length limits for execute_process
    # on Windows & CMake < 3.11
    set(config_env_path "${kconfig_dir}/config.env")
    configure_file("${idf_path}/tools/kconfig_new/config.env.in" ${config_env_path})

    idf_build_set_property(CONFIG_ENV_PATH ${config_env_path})

    idf_build_get_property(root_kconfig __ROOT_KCONFIG)
    idf_build_get_property(root_sdkconfig_rename __ROOT_SDKCONFIG_RENAME)
    idf_build_get_property(python PYTHON)

    # fetch the project sdkconfig file from the build property 
    idf_build_get_property(sdkconfig SDKCONFIG) 
    idf_build_get_property(sdkconfig_defaults SDKCONFIG_DEFAULT)
    
    if (NOT EXISTS ${sdkconfig})
        message(FATAL_ERROR "the ${sdkconfig} file doesn't exists")
    endif()

    
    # fetch the sdkconfig.defaults 
    if(sdkconfig_defaults)
        foreach(sdkconfig_default ${sdkconfig_defaults})
            list(APPEND defaults_arg --defaults "${sdkconfig_default}")
            if(EXISTS "${sdkconfig_default}.${idf_target}")
                list(APPEND defaults_arg --defaults "${sdkconfig_default}.${idf_target}")
            endif()
        endforeach()
    endif()


    set(prepare_kconfig_files_command
        ${python} ${idf_path}/tools/kconfig_new/prepare_kconfig_files.py
        --list-separator=semicolon
        --env-file ${config_env_path})

    set(kconfgen_basecommand
        ${python} ${idf_path}/tools/kconfig_new/confgen.py
        --list-separator=semicolon
        --kconfig ${root_kconfig}
        --sdkconfig-rename ${root_sdkconfig_rename}
        --config ${sdkconfig}
        ${defaults_arg}
        --env-file ${config_env_path})
        
    set(config_dir "${build_dir}/config")


    # Generate the config outputs
    set(sdkconfig_cmake ${config_dir}/sdkconfig.cmake)
    set(sdkconfig_header ${config_dir}/sdkconfig.h)
    set(sdkconfig_json ${config_dir}/sdkconfig.json)
    set(sdkconfig_json_menus ${config_dir}/kconfig_menus.json)


    if(__GENERATE_SDKCONFIG)
        execute_process(
            COMMAND ${prepare_kconfig_files_command})
        execute_process(
            COMMAND ${kconfgen_basecommand}
            --output header ${sdkconfig_header}
            --output cmake ${sdkconfig_cmake}
            --output json ${sdkconfig_json}
            --output json_menus ${sdkconfig_json_menus}
            --output config ${sdkconfig}
            RESULT_VARIABLE config_result
            ERROR_VARIABLE cmd_err
            COMMAND_ECHO STDOUT
                )
    else()
        execute_process(
            COMMAND ${prepare_kconfig_files_command})
        execute_process(
            COMMAND ${kconfgen_basecommand}
            --output header ${sdkconfig_header}
            --output cmake ${sdkconfig_cmake}
            --output json ${sdkconfig_json}
            --output json_menus ${sdkconfig_json_menus}
            RESULT_VARIABLE config_result
            ERROR_VARIABLE cmd_err 
            )
    endif()

    if(config_result)
        message(FATAL_ERROR "Failed to run kconfgen (${kconfgen_basecommand}).
            Command result -- ${config_result} 
            error --> ${cmd_err}")
    endif()

    # When sdkconfig file changes in the future, trigger a cmake run
    set_property(DIRECTORY APPEND PROPERTY CMAKE_CONFIGURE_DEPENDS "${sdkconfig}")

    # Ditto if either of the generated files are missing/modified (this is a bit irritating as it means
    # you can't edit these manually without them being regenerated, but I don't know of a better way...)
    set_property(DIRECTORY APPEND PROPERTY CMAKE_CONFIGURE_DEPENDS "${sdkconfig_header}")
    set_property(DIRECTORY APPEND PROPERTY CMAKE_CONFIGURE_DEPENDS "${sdkconfig_cmake}")

    # Or if the config generation tool changes
    set_property(DIRECTORY APPEND PROPERTY CMAKE_CONFIGURE_DEPENDS "${idf_path}/tools/kconfig_new/confgen.py")

    set_property(DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}" APPEND PROPERTY
                ADDITIONAL_CLEAN_FILES "${sdkconfig_header}" "${sdkconfig_cmake}" "${sdkconfig_json}")

    idf_build_set_property(SDKCONFIG_HEADER ${sdkconfig_header})
    idf_build_set_property(SDKCONFIG_JSON ${sdkconfig_json})
    idf_build_set_property(SDKCONFIG_CMAKE ${sdkconfig_cmake})
    idf_build_set_property(SDKCONFIG_JSON_MENUS ${sdkconfig_json_menus})
    idf_build_set_property(CONFIG_DIR ${config_dir})

    set(MENUCONFIG_CMD ${python} ${idf_path}/tools/kconfig_new/menuconfig_wrapper.py)
    set(TERM_CHECK_CMD ${python} ${idf_path}/tools/check_term.py)

    # Generate the menuconfig target
    add_custom_target(menuconfig
        ${menuconfig_depends}
        # create any missing config file, with defaults if necessary
        COMMAND ${prepare_kconfig_files_command}
        COMMAND ${kconfgen_basecommand}
        --env "IDF_TARGET=${idf_target}"
        --env "IDF_PATH=${idf_path}"
        --env "IDF_ENV_FPGA=${idf_env_fpga}"
        --dont-write-deprecated
        --output config ${sdkconfig}
        COMMAND ${TERM_CHECK_CMD}
        COMMAND ${CMAKE_COMMAND} -E env
        "COMPONENT_KCONFIGS_SOURCE_FILE=${kconfigs_path}"
        "COMPONENT_KCONFIGS_PROJBUILD_SOURCE_FILE=${kconfigs_projbuild_path}"
        "KCONFIG_CONFIG=${sdkconfig}"
        "IDF_TARGET=${idf_target}"
        "IDF_ENV_FPGA=${idf_env_fpga}"
        ${MENUCONFIG_CMD} ${root_kconfig}
        USES_TERMINAL
        # additional run of kconfgen esures that the deprecated options will be inserted into sdkconfig (for backward
        # compatibility)
        COMMAND ${kconfgen_basecommand}
        --env "IDF_TARGET=${idf_target}"
        --env "IDF_PATH=${idf_path}"
        --env "IDF_ENV_FPGA=${idf_env_fpga}"
        --output config ${sdkconfig}
        )

    # Custom target to run kconfserver from the build tool
    add_custom_target(confserver
        COMMAND ${prepare_kconfig_files_command}
        COMMAND ${python} ${idf_path}/tools/kconfig_new/confserver.py
        --env-file ${config_env_path}
        --kconfig ${idf_path}/Kconfig
        --sdkconfig-rename ${root_sdkconfig_rename}
        --config ${sdkconfig}
        VERBATIM
        USES_TERMINAL)

    add_custom_target(save-defconfig
        COMMAND ${prepare_kconfig_files_command}
        COMMAND ${kconfgen_basecommand}
        --dont-write-deprecated
        --output savedefconfig ${CMAKE_SOURCE_DIR}/sdkconfig.defaults
        USES_TERMINAL
        )
endfunction()
