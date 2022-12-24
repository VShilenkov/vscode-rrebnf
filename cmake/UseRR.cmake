include_guard(GLOBAL)

if(TARGET all_rr)
    return()
endif()

set(CF_lp_UseRR "[UseRR]:")


# required to be able to run preprocessing on *.ebnf files
if(NOT CMAKE_CXX_COMPILER)
    enable_language(CXX)
endif()

if(NOT DEFINED RR_COMMAND)
    message(FATAL_ERROR "${CF_lp_UseRR} Railroad diagram generator tool not found. Use `find_package(RR)`")
endif()

add_custom_target(all_rr)

macro(add_rr add_rr_args_TARGET)
    set(cmpa_key_value      DESTINATION)
    set(cmpa_key_multivalue SOURCES INCLUDE_DIRECTORIES)
    cmake_parse_arguments(add_rr_args
                          ""
                          "${cmpa_key_value}"
                          "${cmpa_key_multivalue}"
                          ${ARGN}
    )

    if(TARGET ${add_rr_args_TARGET})
        message(FATAL_ERROR "${CF_lp_UseRR} Target ${add_rr_args_TARGET} is alaready defined")
    endif()

    if(NOT DEFINED add_rr_args_SOURCES)
        message(FATAL_ERROR "${CF_lp_UseRR} Omitted mandatory parameter `SOURCES`")
    elseif(add_rr_args_SOURCES STREQUAL "")
        message(FATAL_ERROR "${CF_lp_UseRR} Values for parameter `SOURCES` are missing")
    endif()

    if(NOT DEFINED add_rr_args_DESTINATION)
        message(FATAL_ERROR "${CF_lp_UseRR} Omitted mandatory parameter `DESTINATION`")
    elseif()
        message(FATAL_ERROR "${CF_lp_UseRR} Value for parameter `DESTINATION` is missing")
    endif()

    # process SOURCES
    set(_rr_SOURCES "")
    foreach(_source IN LISTS add_rr_args_SOURCES)
        cmake_path(IS_RELATIVE _source _is_relative)
        if(_is_relative)
            cmake_path(ABSOLUTE_PATH _source NORMALIZE)
        endif()

        if(NOT EXISTS "${_source}")
            message(FATAL_ERROR "${CF_lp_UseRR} SOURCES contains not existing file: ${_source}")
        endif()
        list(APPEND _rr_SOURCES "${_source}")
    endforeach()
    list(REMOVE_DUPLICATES _rr_SOURCES)

    # process DESTINATION
    cmake_path(IS_RELATIVE add_rr_args_DESTINATION _is_relative)
    if(_is_relative)
        cmake_path(ABSOLUTE_PATH add_rr_args_DESTINATION NORMALIZE)
    endif()
    if(NOT (EXISTS "${add_rr_args_DESTINATION}" AND IS_DIRECTORY "${add_rr_args_DESTINATION}"))
        file(MAKE_DIRECTORY "${add_rr_args_DESTINATION}")
    endif()

    # process INCLUDE_DIRECTORIES
    ## add current location to includes
    set(_rr_INCLUDE_DIRECTORIES "${CMAKE_CURRENT_LIST_DIR}")
    foreach(_dir IN LISTS add_rr_args_INCLUDE_DIRECTORIES)
        cmake_path(IS_RELATIVE _dir _is_relative)
        if(_is_relative)
            cmake_path(ABSOLUTE_PATH _dir NORMALIZE)
        endif()

        if(NOT EXISTS "${_dir}")
            message(WARNING "${CF_lp_UseRR} `INCLUDE_DIRECTORIES` contains not existing directory: ${_dir}")
        elseif(NOT IS_DIRECTORY "${_dir}")
            message(WARNING "${CF_lp_UseRR} `INCLUDE_DIRECTORIES` contains not directory: ${_dir}")
        else()
            list(APPEND _rr_INCLUDE_DIRECTORIES "${_dir}")
        endif()
    endforeach()
    list(REMOVE_DUPLICATES _rr_INCLUDE_DIRECTORIES)
    list(TRANSFORM _rr_INCLUDE_DIRECTORIES PREPEND "-I")

    set(_rr_PRODUCTS "")
    foreach(_source IN LISTS _rr_SOURCES)
        cmake_path(GET _source STEM LAST_ONLY _source_full_stem)

        add_custom_command(OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/${_source_full_stem}.pp.ebnf
            COMMAND
                ${CMAKE_CXX_COMPILER}
                    -E
                    -C
                    -x c++-header
                    ${_rr_INCLUDE_DIRECTORIES}
                    -o ${CMAKE_CURRENT_BINARY_DIR}/${_source_full_stem}.pp.ebnf
                    ${_source}
            DEPENDS ${_source}
            COMMENT "${CF_lp_UseRR} Preprocess ${_source}"
        )

        add_custom_command(OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/${_source_full_stem}.s.ebnf
            COMMAND
                grep
                    -v "^#"
                    ${CMAKE_CURRENT_BINARY_DIR}/${_source_full_stem}.pp.ebnf > ${CMAKE_CURRENT_BINARY_DIR}/${_source_full_stem}.s.ebnf
            DEPENDS ${CMAKE_CURRENT_BINARY_DIR}/${_source_full_stem}.pp.ebnf
            COMMENT "${CF_lp_UseRR} Sanityze ${CMAKE_CURRENT_BINARY_DIR}/${_source_full_stem}.pp.ebnf"
        )

        add_custom_command(OUTPUT ${add_rr_args_DESTINATION}/${_source_full_stem}.xhtml
            COMMAND
                ${RR_COMMAND}
                    -out:${add_rr_args_DESTINATION}/${_source_full_stem}.xhtml
                    ${CMAKE_CURRENT_BINARY_DIR}/${_source_full_stem}.s.ebnf
            DEPENDS ${CMAKE_CURRENT_BINARY_DIR}/${_source_full_stem}.s.ebnf
            COMMENT "${CF_lp_UseRR} Generate ${add_rr_args_DESTINATION}/${_source_full_stem}.xhtml"
        )

        list(APPEND _rr_PRODUCTS "${add_rr_args_DESTINATION}/${_source_full_stem}.xhtml")

    endforeach()

    add_custom_target(${add_rr_args_TARGET}
        DEPENDS ${_rr_PRODUCTS}
    )

    add_dependencies(all_rr ${add_rr_args_TARGET})
endmacro()

