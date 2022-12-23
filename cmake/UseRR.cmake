
# required to be able to run preprocessing on *.ebnf files
if(NOT CMAKE_C_COMPILER)
    enable_language(CXX)
endif()

if(NOT DEFINED RR_COMMAND)
    message(FATAL_ERROR "Railroad diagram generator tool not found. Use `find_package(RR)`")
endif()

macro(generate_rr)
    set(key_value DESTINATION)
    set(key_multivalue SOURCES INCLUDE_DIRECTORIES)
    cmake_parse_arguments(_generate_rr_args "" "${key_value}" "${key_multivalue}" ${ARGN})

    if(NOT DEFINED _generate_rr_args_SOURCES OR NOT _generate_rr_args_SOURCES)
        message(FATAL_ERROR "SOURCES is mandatory field to generate_rr macro")
    endif()

    if(NOT DEFINED _generate_rr_args_DESTINATION OR NOT _generate_rr_args_DESTINATION)
        message(FATAL_ERROR "DESTINATION is mandatory field to generate_rr macro")
    endif()


    set(_sources_to_process "")
    foreach(_source IN LISTS _generate_rr_args_SOURCES)
        cmake_path(IS_RELATIVE _source _is_relative)
        if(_is_relative)
            cmake_path(ABSOLUTE_PATH _source)
        endif()

        if(NOT EXISTS "${_source}")
            message(FATAL_ERROR "source file provided cannot be found: ${_source}")
        endif()
        list(APPEND _sources_to_process "${_source}")
    endforeach()
    
    if(NOT EXISTS "${_generate_rr_args_DESTINATION}" OR NOT IS_DIRECTORY "${_generate_rr_args_DESTINATION}")
        file(MAKE_DIRECTORY ${_generate_rr_args_DESTINATION})
    endif()

    set(_rr_include_directories "")
    foreach(rr_inc_dir IN LISTS _generate_rr_args_INCLUDE_DIRECTORIES)
        cmake_path(IS_RELATIVE rr_inc_dir _is_relative)
        if(_is_relative)
            cmake_path(ABSOLUTE_PATH rr_inc_dir)
        endif()

        if(NOT EXISTS "${rr_inc_dir}")
            message(WARNING "Provided include directory doesn't exist ${rr_inc_dir}")
        elseif(NOT IS_DIRECTORY "${rr_inc_dir}")
            message(WARNING "Provided include path is not directory ${rr_inc_dir}")
        else()
            list(APPEND _rr_include_directories "${rr_inc_dir}")
        endif()
    endforeach()

    list(TRANSFORM _rr_include_directories PREPEND "-I")
    list(REMOVE_DUPLICATES _sources_to_process)

    foreach(_source IN LISTS _sources_to_process)
        cmake_path(GET _source STEM LAST_ONLY full_stem)

        file(STRINGS ${_source} _origin_content NEWLINE_CONSUME)
        
        #message(STATUS "${_origin_content}")
        if(EXISTS ${CMAKE_CURRENT_BINARY_DIR}/${full_stem}.orign.egnf)
            file(REMOVE ${CMAKE_CURRENT_BINARY_DIR}/${full_stem}.orign.egnf)
        endif()

        string(REPLACE "//" "|double_forwards_slash|" _origin_content "${_origin_content}")
        #string(REPLACE "'" "|:apostrofe:|" _origin_content "${_origin_content}")
        #string(REPLACE "\"" "|:quotation:|" _origin_content "${_origin_content}")
        #string(REPLACE "/*" "|block_comment_starts|" _origin_content "${_origin_content}")
        #string(REPLACE "*/" "|block_comment_ends|" _origin_content "${_origin_content}")
        string(REPLACE ";" "|semicolon|" _origin_content "${_origin_content}")
        file(APPEND ${CMAKE_CURRENT_BINARY_DIR}/${full_stem}.orign.egnf "${_origin_content}")
        

        execute_process(COMMAND 
            ${CMAKE_CXX_COMPILER} -E -C ${_rr_include_directories} -x c++-header ${CMAKE_CURRENT_BINARY_DIR}/${full_stem}.orign.egnf -o ${CMAKE_CURRENT_BINARY_DIR}/${full_stem}.ppebnf
            RESULT_VARIABLE _pp_result
            OUTPUT_VARIABLE _pp_output
            ERROR_VARIABLE _pp_error
            COMMAND_ECHO STDOUT
            ECHO_OUTPUT_VARIABLE
            ECHO_ERROR_VARIABLE
        )

        if(NOT _pp_result EQUAL 0)
            message(WARNING "Preprocess failed ${_pp_output} ${_pp_error}")
        endif()

        if(NOT EXISTS ${CMAKE_CURRENT_BINARY_DIR}/${full_stem}.ppebnf)
            message(FATAL_ERROR "preprocessed file not generated ${CMAKE_CURRENT_BINARY_DIR}/${full_stem}.ppebnf")
        endif()

        file(READ ${CMAKE_CURRENT_BINARY_DIR}/${full_stem}.ppebnf _content ENCODING UTF-8)
        if(EXISTS ${CMAKE_CURRENT_BINARY_DIR}/${full_stem}.reworked.ebnf)
            file(REMOVE ${CMAKE_CURRENT_BINARY_DIR}/${full_stem}.reworked.ebnf)
        endif()

        string(REPLACE "\n" ";" _content "${_content}")
        string(PREPEND _content ";")
        string(REGEX MATCHALL ";#[^;]*" to_remove "${_content}")
        list(SORT to_remove ORDER DESCENDING)
        message(STATUS "${to_remove}")
        foreach(_line  ${to_remove})
            #if(_line MATCHES "^[^G].*$")
                #message(STATUS "${_line}")
                #message(STATUS "Before")
                #message(STATUS "${_content}")
                string(REPLACE "${_line}" ";" _content "${_content}")
                #message(STATUS "After")
                #message(STATUS "${_content}")
                ##file(APPEND ${CMAKE_CURRENT_BINARY_DIR}/${full_stem}.ebnf "${_line}")
            #endif()
        endforeach()

        #message(STATUS "${_content}")
        string(REPLACE "|double_forwards_slash|" "//"  _content "${_content}")
        #string(REPLACE "|block_comment_starts|" "/*"  _content "${_content}")
        #string(REPLACE "|block_comment_ends|" "*/"  _content "${_content}")
        #string(REPLACE "|:apostrofe:|" "'" _content "${_content}")
        #string(REPLACE "|:quotation:|" "\"" _content "${_content}")
        string(REPLACE ";" "\n" _content "${_content}")
        string(REPLACE "|semicolon|" ";"  _content "${_content}")
        file(WRITE ${CMAKE_CURRENT_BINARY_DIR}/${full_stem}.reworked.ebnf "${_content}")

        execute_process(COMMAND 
                ${RR_COMMAND} -out:${_generate_rr_args_DESTINATION}/${full_stem}.xhtml ${CMAKE_CURRENT_BINARY_DIR}/${full_stem}.reworked.ebnf
            RESULT_VARIABLE rr_result
            OUTPUT_VARIABLE rr_output
            ERROR_VARIABLE rr_error
        )
    endforeach()
#  /usr/bin/java -jar /home/vsh/Hearth/sources/git/github.com/VShilenkov/vscode-rrebnf/build/_deps/rr_jar_package-src/rr.war -out:test.xhtml ./tests/rr.syntax.ebnf 
endmacro()