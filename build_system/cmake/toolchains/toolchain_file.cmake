################################################################################
# toolchain_file.cmake
#
# Author: [Himanshu Jangra]
# Date: [23-Feb-2024]
#
# Description:
#   	toolchain file for the esp targets there are certain targets but for now we only 
#       using esp32 target .
#
# Notes:
#       Please dont modify existing CMAKE function and commands unless highly required 
# 		 Additional notes
#       functions that have a double underscore prefix will be used by that cmake file internally 
#
################################################################################
# [Contents of the file below]
# check for minimum cmake version to run this script
cmake_minimum_required(VERSION 3.2.1)


# include the compiler checker cmake module
include(CheckCCompilerFlag)
include(CheckCXXCompilerFlag)


# @name toolchain_init 
#    
# @param0 target 
# @note    used to specify the toolchain file for the specified target 
# @usage   usage  
# @scope  parent_scope
# scope tells where should this cmake function used 
# 
macro(toolchain_init target)
    message(STATUS "initialising Project target <<<${target}>>> toolchain file")
    __target_set_toolchain(${target})

    # This must be called after setting the toolchain file, otherwise the compiler will 
    # be set to defualt clang or gcc , but we need to enable this here as we have to enable 
    # the compiler by this command and this is a prerequisite for the checkCcompiler function 
    enable_language(C CXX ASM)

    __target_check_toolchain(${target})
    # check some flags of the target
    # @todo skipped for now 
    # __toolchain_check_flags(${target})
    # init the compilation flags 
    __toolchain_flags_init(${target})
endmacro()


# @name __target_set_toolchain 
#   
# @param0  target  
# @note    used to set the toolchain for compiling the project 
# @usage    used in target init
# @scope  only yhis file   
# scope tells where should this cmake function used 
# 
macro(__target_set_toolchain target)
    
    # get the path "cmake scripts path" from the __idf_build_target property  
    idf_build_get_property(cmake_scripts_path CMAKE_SCRIPTS_PATH)

    set(cmake_scripts_path "${cmake_scripts_path}/toolchains")
    file(TO_CMAKE_PATH   "${cmake_scripts_path}" cmake_scripts_path)

    # find the toolchain file in the path 
    find_file(toolchain_file "toolchain-${target}.cmake" PATHS "${cmake_scripts_path}"  REQUIRED )
    
    # Finally, set TOOLCHAIN_FILE in cache
    set(TOOLCHAIN_FILE ${toolchain_file} CACHE STRING "IDF Build Toolchain FILE")

    # Check if selected target is consistent with toolchain file in CMake cache
    if(DEFINED CMAKE_TOOLCHAIN_FILE)
        # try to match the toolchain file components
        get_filename_component(exist_toolchain_file "${CMAKE_TOOLCHAIN_FILE}"  NAME)
        get_filename_component(our_toolchain_file  "$CACHE{TOOLCHAIN_FILE}" NAME)

        # check if this variables is defined before 
        # match the toolchain file with the input target 
        if(NOT("${exist_toolchain_file}" MATCHES "${our_toolchain_file}"))
            message(FATAL_ERROR "toolchain file mismatches Function toolchain file ${our_toolchain_file}
                    Existing toolchain file ${exist_toolchain_file} ")
        endif()

    endif()

    # set the toolchain file cmake variable this takes a global effect in the project 
    set(CMAKE_TOOLCHAIN_FILE ${toolchain_file})
  
endmacro()


# @name target_check_toolchain 
#   
# @param0  target  
# @note    check the toolchain for the target, check if it is working properly
# @usage   toolchain_init   
# @scope   this file only
# scope tells where should this cmake function used 
# 
macro(__target_check_toolchain target)

    # if(DEFINED CACHE{C_COMPILER_STANDARD} AND DEFINED CACHE{CXX_COMPILER_STANDARD})
    #     message(STATUS "Compiler checks (flags and standard) already done !!")
    #     # initing the falgs and then return otherwuse this functions doesn;'t executed 
    #     __toolchain_flags_init(${target})
    #     return()
    # endif()

    # getting the compiler name first 
    get_filename_component(compiler_name ${CMAKE_C_COMPILER} NAME_WLE)
    
    # test the compiler supported targets 
    execute_process(COMMAND ${CMAKE_C_COMPILER} -dumpmachine
                    OUTPUT_VARIABLE TARGET_MACHINE
                    ERROR_VARIABLE COMPILER_ERROR
                    RESULT_VARIABLE COMMAND_RESULT
                    OUTPUT_STRIP_TRAILING_WHITESPACE
                    WORKING_DIRECTORY "${CMAKE_BINARY_DIR}" 
                    COMMAND_ECHO STDOUT
                    )
    
    if(COMMAND_RESULT EQUAL 0)
        message(STATUS "${compiler_name} supports target is ${TARGET_MACHINE}")
    else()
        message(WARNING "${compiler_name} giving error on excuting the command -dumpmachine")
    endif()

    # --------------------------------------------------------------------------
    # Check if the compiler supports a specific flag
    check_c_compiler_flag("-Wall" COMPILER_SUPPORTS_WALL)
    include(CheckCXXCompilerFlag )
    # --------------------------------------------------------------------------
    # check for other compiler features 
    #  TODO
    # --------------------------------------------------------------------------
    # check the compiler standard 
    set(preferred_c_versions gnu23 gnu17 gnu11 gnu99)
    
    set(c_standard_ver "")

    foreach(c_version ${preferred_c_versions})
        check_c_compiler_flag("-std=${c_version}" C_COMPILER_${c_version}_SUPPORTED)
        if(C_COMPILER_${c_version}_SUPPORTED)
            set(c_standard_ver ${c_version})
            break()
        endif()
    endforeach()
    
    if(NOT c_standard_ver)
        message(FATAL_ERROR "Can't find a compiler standards within the ${preferred_c_versions}")
    endif()

    
    # -----------------------------------------------------------------------------
    # ======================== check CXX compiler standardisation ==================

    set(preferred_cxx_versions  gnu++23  gnu++20 gnu++2a gnu++17 gnu++14)
    
    set(cxx_standard_ver "")

    foreach(cxx_version ${preferred_cxx_versions})
        check_cxx_compiler_flag("-std=${cxx_version}" CXX_COMPILER_${cxx_version}_SUPPORTED)
        if(CXX_COMPILER_${cxx_version}_SUPPORTED)
            set(cxx_standard_ver ${cxx_version})
            break()
        endif()
    endforeach()
    
    if(NOT cxx_standard_ver)
        message(FATAL_ERROR "Can't find a compiler standards within the ${preferred_cxx_versions}")
    endif()

    
    # Use regex to extract the number
    string(REGEX REPLACE "[^0-9]" "" c_standard_ver "${c_standard_ver}")
    string(REGEX REPLACE "[^0-9]" "" cxx_standard_ver "${cxx_standard_ver}")

    # setting the cache variables for the compiler standard 
    set(C_COMPILER_STANDARD ${c_standard_ver} CACHE STRING "C Compiler latest standard")
    set(CXX_COMPILER_STANDARD ${cxx_standard_ver} CACHE STRING "C++ Compiler standard" )

    # turn on the compiler standard that should be present in the flags 
    set(CMAKE_C_STANDARD_REQUIRED ON)
    set(CMAKE_CXX_STANDARD_REQUIRED ON)

    # turn on the language extension
    set(CMAKE_C_EXTENSIONS ON)
    set(CMAKE_CXX_EXTENSIONS ON)

    message(STATUS "C standard = ${C_COMPILER_STANDARD}  CXX standard = ${CXX_COMPILER_STANDARD}" )
    set(CMAKE_C_STANDARD ${C_COMPILER_STANDARD})
    set(CMAKE_CXX_STANDARD ${CXX_COMPILER_STANDARD})



endmacro()


# @name __target_check_flags 
#   
# @param0  target 
# @note    used to check ceratin flags of the toolchain like size of datatype time_t  
# @usage   usage  
# @scope  scope   
# scope tells where should this cmake function used 
# 
function(__toolchain_check_flags target)
    # For the transition period from 32-bit time_t to 64-bit time_t,
    # auto-detect the size of this type and set corresponding variable.
    #  @todo have to enable it but giving error
    include(CheckTypeSize)
    check_type_size("time_t" TIME_T_SIZE LANGUAGE C)
    if(HAVE_TIME_T_SIZE)
        message(WARNING "the time_t has the following value ${TIME_T_SIZE}")
        idf_build_set_property(TIME_T_SIZE ${TIME_T_SIZE})
    else()
        message(FATAL_ERROR "Failed to determine sizeof(time_t)")
    endif()

endfunction()


# @name toolchain_flags_init 
#   
# @param target 
# @note    used to init the GLOBAL toolchain flags used  in compiling the project
# @usage   used to init the compiler 
# @scope  this file only  
# scope tells where should this cmake function used 
# 
function(__toolchain_flags_init target)
    # initing the basic flags for the toolchain 

    idf_build_get_property(idf_path IDF_PATH)

    set(compile_options "")
    set(c_compile_options "")
    set(cxx_compile_options "")
    set(asm_compile_options "")

    set(link_options "")
    
    set(compile_definitions "")
    # Variables compile_options, c_compile_options, cxx_compile_options, 
    # compile_definitions, link_options shall
    # not be unset as they may already contain flags, set by toolchain_file.cmake files.

    # Add the following build specifications here, since these seem to be dependent
    # on config values on the root Kconfig.

    if(BOOTLOADER_BUILD)
        if(CONFIG_BOOTLOADER_COMPILER_OPTIMIZATION_SIZE )
            list(APPEND compile_options  "-Os")
        elseif(CONFIG_BOOTLOADER_COMPILER_OPTIMIZATION_DEBUG)
            list(APPEND compile_options  "-Og")
        elseif(CONFIG_BOOTLOADER_COMPILER_OPTIMIZATION_PERF)
            list(APPEND compile_options  "-O2")
        elseif(CONFIG_BOOTLOADER_COMPILER_OPTIMIZATION_NONE)
            list(APPEND compile_options  "-O0")
        endif()
    else()
        if(CONFIG_COMPILER_OPTIMIZATION_SIZE)
            list(APPEND compile_options "-Os")
        elseif(CONFIG_COMPILER_OPTIMIZATION_DEFAULT)
            list(APPEND compile_options "-Og")
        elseif(CONFIG_COMPILER_OPTIMIZATION_NONE)
            list(APPEND compile_options "-O0")
        elseif(CONFIG_COMPILER_OPTIMIZATION_PERF)
            list(APPEND compile_options "-O2")
        endif()

    endif()

    
    if(CMAKE_C_COMPILER_ID MATCHES "GNU")
        # This flag is GCC-specific.
        # Not clear yet if some other flag should be used for Clang.
        list(APPEND compile_options "-freorder-blocks" 
                        "-fno-tree-switch-conversion"
                        "-fstrict-volatile-bitfields")
        
    endif()

    if(CONFIG_COMPILER_CXX_EXCEPTIONS)
        list(APPEND cxx_compile_options "-fexceptions")
        else()
        list(APPEND cxx_compile_options "-fno-exceptions")
    endif()

    if(CONFIG_COMPILER_CXX_RTTI)
        list(APPEND cxx_compile_options "-frtti")
        else()
        list(APPEND cxx_compile_options "-fno-rtti")
        list(APPEND link_options "-fno-rtti")           # used to invoke correct multilib variant (no-rtti) during linking
    endif()

    if(CONFIG_COMPILER_SAVE_RESTORE_LIBCALLS)
        list(APPEND compile_options "-msave-restore")
    endif()

    
    if(CONFIG_COMPILER_WARN_WRITE_STRINGS)
        list(APPEND compile_options "-Wwrite-strings")
    endif()

    if(CONFIG_COMPILER_OPTIMIZATION_ASSERTIONS_DISABLE)
        list(APPEND compile_definitions "-DNDEBUG")
    endif()

    if(CONFIG_COMPILER_STACK_CHECK_MODE_NORM)
        list(APPEND compile_options "-fstack-protector")
    elseif(CONFIG_COMPILER_STACK_CHECK_MODE_STRONG)
        list(APPEND compile_options "-fstack-protector-strong")
    elseif(CONFIG_COMPILER_STACK_CHECK_MODE_ALL)
        list(APPEND compile_options "-fstack-protector-all")
    endif()

    if(CONFIG_COMPILER_DUMP_RTL_FILES)
        list(APPEND compile_options "-fdump-rtl-expand")
    endif()

    # if(NOT ${CMAKE_C_COMPILER_VERSION} VERSION_LESS 8.0.0)
    if(CONFIG_COMPILER_HIDE_PATHS_MACROS)
        list(APPEND compile_options "-fmacro-prefix-map=${CMAKE_SOURCE_DIR}=."
                                    "-fmacro-prefix-map=${idf_path}=/IDF")
    endif()

    if(CONFIG_APP_REPRODUCIBLE_BUILD)
        message(STATUS "APP is set to make reproducible builds")
        idf_build_set_property(DEBUG_PREFIX_MAP_GDBINIT "${BUILD_DIR}/prefix_map_gdbinit")

        list(APPEND compile_options "-fdebug-prefix-map=${idf_path}=/IDF")
        list(APPEND compile_options "-fdebug-prefix-map=${PROJECT_DIR}=/IDF_PROJECT")
        list(APPEND compile_options "-fdebug-prefix-map=${BUILD_DIR}=/IDF_BUILD")

        # component dirs
        idf_build_get_property(python PYTHON)
        idf_build_get_property(component_dirs BUILD_COMPONENT_DIRS)

        execute_process(
            COMMAND ${python}
                "${idf_path}/tools/generate_debug_prefix_map.py"
                "${BUILD_DIR}"
                "${component_dirs}"
            OUTPUT_VARIABLE result
            RESULT_VARIABLE ret
        )
        if(NOT ret EQUAL 0)
            message(FATAL_ERROR "This is a bug. Please report to https://github.com/espressif/esp-idf/issues")
        endif()

        spaces2list(result)
        list(LENGTH component_dirs length)
        math(EXPR max_index "${length} - 1")
        foreach(index RANGE ${max_index})
            list(GET component_dirs ${index} folder)
            list(GET result ${index} after)
            list(APPEND compile_options "-fdebug-prefix-map=${folder}=${after}")
        endforeach()
    endif()

    if(CONFIG_COMPILER_DISABLE_GCC12_WARNINGS)
        list(APPEND compile_options "-Wno-address"
                                "-Wno-use-after-free")
    endif()

 
    if(CONFIG_ESP_SYSTEM_USE_EH_FRAME)
        list(APPEND compile_options "-fasynchronous-unwind-tables")
        list(APPEND link_options "-Wl,--eh-frame-hdr")
    endif()

    list(APPEND link_options "-fno-lto")

    if(CONFIG_IDF_TARGET_LINUX AND CMAKE_HOST_SYSTEM_NAME STREQUAL "Darwin")
        list(APPEND link_options "-Wl,-dead_strip")
        list(APPEND link_options "-Wl,-warn_commons")
    else()
        list(APPEND link_options "-Wl,--gc-sections")
        list(APPEND link_options "-Wl,--warn-common")
    endif()

    # SMP FreeRTOS user provided minimal idle hook. This allows the user to provide
    # their own copy of vApplicationMinimalIdleHook()
    if(CONFIG_FREERTOS_USE_MINIMAL_IDLE_HOOK)
        list(APPEND link_options "-Wl,--wrap=vApplicationMinimalIdleHook")
    endif()

    # Placing jump tables in flash would cause issues with code that required
    # to be placed in IRAM
    list(APPEND compile_options "-fno-jump-tables")
    
    # Clang finds some warnings in IDF code which GCC doesn't.
    # All these warnings should be fixed before Clang is presented
    # as a toolchain choice for users.
    if(CMAKE_C_COMPILER_ID MATCHES "Clang")
        # Clang checks Doxygen comments for being in sync with function prototype.
        # There are some inconsistencies, especially in ROM headers.
        list(APPEND compile_options 
                            "-Wno-documentation"
        # GCC allows repeated typedefs when the source and target types are the same.
        # Clang doesn't allow this. This occurs in many components due to forward
        # declarations.
                            "-Wno-typedef-redefinition"
        # This issue is seemingly related to newlib's char type functions.
        # Fix is not clear yet.
                            "-Wno-char-subscripts"
        # Clang seems to notice format string issues which GCC doesn't.
                            "-Wno-format-security"
        # Logic bug in essl component
                            "-Wno-tautological-overlap-compare"
        # Some pointer checks in mDNS component check addresses which can't be NULL
                            "-Wno-tautological-pointer-compare"
        # Similar to the above, in tcp_transport
                            "-Wno-pointer-bool-conversion"
        # mbedTLS md5.c triggers this warning in md5_test_buf (false positive)
                            "-Wno-string-concatenation"
        # multiple cases of implict convertions between unrelated enum types
                            "-Wno-enum-conversion"
        # When IRAM_ATTR is specified both in function declaration and definition,
        # it produces different section names, since section names include __COUNTER__.
        # Occurs in multiple places.
                            "-Wno-section"
        # Multiple cases of attributes unknown to clang, for example
        # __attribute__((optimize("-O3")))
                            "-Wno-unknown-attributes"
        # Disable Clang warnings for atomic operations with access size
        # more then 4 bytes
                            "-Wno-atomic-alignment"
        # several warnings in wpa_supplicant component
                            "-Wno-unused-but-set-variable"
        # Clang also produces many -Wunused-function warnings which GCC doesn't.
                            "-Wno-unused-function"
        # many warnings in bluedroid code
        # warning: field 'hdr' with variable sized type 'BT_HDR' not at the end of a struct or class is a GNU extension
                            "-Wno-gnu-variable-sized-type-not-at-end"
        # several warnings in bluedroid code
                            "-Wno-constant-logical-operand"
        # warning: '_Static_assert' with no message is a C2x extension
                            "-Wno-c2x-extensions"
        # warning on                    size 0 for C and 1 for C+
                            "-Wno-extern-c-compat" 
                            "-fno-use-cxa-atexit")
    endif()

    # More warnings may exist in unit tests and example projects.
    # get_property(c_fet GLOBAL PROPERTY CMAKE_C_KNOWN_FEATURES)
    # message(STATUS "cmake c known features ${c_fet}")

    
    list(APPEND c_compile_options "${compile_options}")
    list(APPEND cxx_compile_options "${compile_options}")
    list(APPEND asm_compile_options "${compile_options}")
    
    idf_build_set_property(COMPILE_DEFINITIONS "${compile_definitions}" APPEND)

    idf_build_set_property(COMPILE_OPTIONS "${compile_options}" APPEND)
    idf_build_set_property(C_COMPILE_OPTIONS "${c_compile_options}" APPEND)
    idf_build_set_property(CXX_COMPILE_OPTIONS "${cxx_compile_options}" APPEND)
    idf_build_set_property(ASM_COMPILE_OPTIONS "${asm_compile_options}" APPEND)
    idf_build_set_property(LINK_OPTIONS "${link_options}" APPEND)


    message(STATUS "compile options ${compile_options} ")
    message(STATUS "c compile options ${c_compile_options}")
    message(STATUS "cxx compile options ${cxx_compile_options}")
    message(STATUS "link options ${link_options}")
    message(STATUS "C Known features  ${CMAKE_C_COMPILE_FEATURES}")
    # message(STATUS "CXX known features ${CMAKE_CXX_COMPILE_FEATURES}")

endfunction()

# -DconfigENABLE_FREERTOS_DEBUG_OCDAWARE=1






