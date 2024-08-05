################################################################################
# ldgen.cmake
#
# Description:
#   	this will read the .lf files and convert it into .ld files for the linker .
#
# Notes:
#       Please dont modify existing CMAKE function and commands unless highly required 
# 		 Additional notes
#
################################################################################
# [Contents of the file below]
# check for minimum cmake version to run this script
cmake_minimum_required(VERSION 3.2.1)


# @name ld_ldgen_tool_init 
#    
# @note    init the ldgen basic utility tools     
# @usage   used in build init or esp_idf_init 
# @scope  scope   
# scope tells where should this cmake function used 
# 
function(ld_ldgen_env_init )

    # get the build process and then call it 
    idf_build_get_property(build_dir BUILD_DIR)
    if(BOOTLOADER_BUILD)
        return()
    endif()
    # create a ldgen directory in the build dir 
    file(MAKE_DIRECTORY  ${build_dir}/ld)

endfunction()


# Utilities for supporting linker script generation in the build system

# __ldgen_add_fragment_files
#
# Add one or more linker fragment files, and append it to the list of fragment
# files found so far.
function(__ldgen_add_fragment_files fragment_files)
    spaces2list(fragment_files)

    foreach(fragment_file ${fragment_files})
        get_filename_component(abs_path ${fragment_file} ABSOLUTE)
        list(APPEND _fragment_files ${abs_path})
    endforeach()

    idf_build_set_property(__LDGEN_FRAGMENT_FILES "${_fragment_files}" APPEND)
endfunction()

# __ldgen_add_component
#
# Generate sections info for specified target to be used in linker script generation
function(__ldgen_add_component component_lib)
    idf_build_set_property(__LDGEN_LIBRARIES "$<TARGET_FILE:${component_lib}>" APPEND)
    idf_build_set_property(__LDGEN_DEPENDS ${component_lib} APPEND)
endfunction()

# __ldgen_process_template
#
# Passes a linker script template to the linker script generation tool for
# processing
function(__ldgen_process_template target template output)
    
    message(STATUS "Converting Linker Fragment ${template} file for \
     the target ${target} into .ld files ${output}")
            
    idf_build_get_property(idf_path IDF_PATH)

    # get the build dir from property
    idf_build_get_property(build_dir BUILD_DIR)

    idf_build_get_property(ldgen_libraries __LDGEN_LIBRARIES GENERATOR_EXPRESSION)

    file(GENERATE OUTPUT "${build_dir}/ld/ldgen_libraries.in" CONTENT $<JOIN:${ldgen_libraries},\n>)
    file(GENERATE OUTPUT "${build_dir}/ld/ldgen_libraries" INPUT "${build_dir}/ld/ldgen_libraries.in")

    set_property(DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}"
        APPEND PROPERTY ADDITIONAL_CLEAN_FILES
        "${build_dir}/ld/ldgen_libraries.in"
        "${build_dir}/ld/ldgen_libraries")

    idf_build_get_property(ldgen_fragment_files __LDGEN_FRAGMENT_FILES GENERATOR_EXPRESSION)
    idf_build_get_property(ldgen_depends __LDGEN_DEPENDS GENERATOR_EXPRESSION)
    # Create command to invoke the linker script generator tool.
    idf_build_get_property(sdkconfig SDKCONFIG)
    idf_build_get_property(root_kconfig __ROOT_KCONFIG)

    idf_build_get_property(python PYTHON)

    idf_build_get_property(config_env_path CONFIG_ENV_PATH)

    if($ENV{LDGEN_CHECK_MAPPING})
        set(ldgen_check "--check-mapping"
            "--check-mapping-exceptions" "${idf_path}/tools/ci/check_ldgen_mapping_exceptions.txt")
        message(STATUS "Mapping check enabled in ldgen")
    endif()

    add_custom_command(
        OUTPUT ${output}
        COMMAND ${python} "${idf_path}/tools/ldgen/ldgen.py"
        --config    "${sdkconfig}"
        --fragments-list "${ldgen_fragment_files}"
        --input     "${template}"
        --output    "${output}"
        --kconfig   "${root_kconfig}"
        --env-file  "${config_env_path}"
        --libraries-file "${build_dir}/ld/ldgen_libraries"
        --objdump   "${CMAKE_OBJDUMP}"
        ${ldgen_check}
        # run in the binary directory 
        WORKING_DIRECTORY ${build_dir}
        DEPENDS     ${template} ${ldgen_fragment_files} ${ldgen_depends} ${SDKCONFIG}
        VERBATIM
        USES_TERMINAL
    )

    # add the dependency of the project into the target 
    get_filename_component(_name ${output} NAME)
    add_custom_target(__ldgen_output_${_name} DEPENDS ${output})
    add_dependencies(__idf_build_target __ldgen_output_${_name})
    # add_dependencies(${target} __idf_build_target)
    idf_build_set_property(__LINK_DEPENDS ${output} APPEND)

endfunction()



