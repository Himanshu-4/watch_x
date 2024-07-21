cmake_minimum_required(VERSION 3.2)

# --------- override the default message behaviour of  cmake --------------------------------------- 
function(message)

    string(ASCII 27 Esc)

    set(ColourReset "${Esc}[m")
    set(ColourBold  "${Esc}[1m")
    set(Red         "${Esc}[31m")
    set(Green       "${Esc}[32m")
    set(Yellow      "${Esc}[33m")
    set(Blue        "${Esc}[34m")
    set(Magenta     "${Esc}[35m")
    set(Cyan        "${Esc}[36m")
    set(White       "${Esc}[37m")
    set(BoldRed     "${Esc}[1;31m")
    set(BoldGreen   "${Esc}[1;32m")
    set(BoldYellow  "${Esc}[1;33m")
    set(BoldBlue    "${Esc}[1;34m")
    set(BoldMagenta "${Esc}[1;35m")
    set(BoldCyan    "${Esc}[1;36m")
    set(BoldWhite   "${Esc}[1;37m")
  
    #"  based on the message type we can colorize the output on terminal 
    # cmake_parse_arguments(_ "STATUS" )
    set(color "")
    set(type ${ARGV0})

    if(${type} STREQUAL "STATUS")
        set(color ${BoldGreen}) # green color for STATUS
        
    elseif(${type} STREQUAL "VERBOSE")
        set(color ${BoldBlue})

    elseif(${type} STREQUAL "WARNING" OR ${type} STREQUAL "DEPRECATION")
        set(color ${BoldYellow}) # Yellow color for WARNING
    
    elseif(${type} STREQUAL "AUTHOR_WARNING")
        set(color ${BoldBlue}) # Magenta color for AUTH[OR_WARNING
    
    elseif(${type} STREQUAL "SEND_ERROR" OR ${type} STREQUAL "FATAL_ERROR")
        set(color ${BoldRed}) # Red color for SEND_ERROR

    elseif(${type} STREQUAL "DEBUG")
        set(color ${BoldCyan})
    
    else()
        set(color ${BoldWhite})
        #  also set the type to null
        set(type "")
    endif()

    list(REMOVE_AT ARGV 0)

    # Call original message function
    _message("${type}" "${color} ${ARGV} ${ColourReset}")

endfunction()




