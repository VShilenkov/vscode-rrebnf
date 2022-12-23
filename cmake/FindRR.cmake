# includes ------------------------------------------------------------------- #
include(FeatureSummary)
include(FindPackageHandleStandardArgs)

set(_cmff_NAME RR)

# declare package properties ------------------------------------------------- #
set_package_properties(${_cmff_NAME}
    PROPERTIES
        URL         "https://bottlecaps.de/rr/ui"
        DESCRIPTION "A Tool for generation railroad diagrams"
)

# validate find_package() arguments ------------------------------------------ #
## components ---------------------------------------------------------------- #

if(DEFINED ${_cmff_NAME}_FIND_COMPONENTS AND NOT(${_cmff_NAME}_FIND_COMPONENTS STREQUAL ""))
    message(WARNING "${_cmff_NAME} doesn't support components")
endif()

## hints --------------------------------------------------------------------- #
set(${_cmff_NAME}_hints "")
foreach(dir ${_cmff_NAME}_DIR ${_CMFF_NAME}_DIR)
    if(DEFINED ${dir})
        list(APPEND ${_cmff_NAME}_hints "${${dir}}")
    endif()
endforeach()
unset(dir)

# dependencies --------------------------------------------------------------- #
find_package(Java REQUIRED COMPONENTS Runtime)

include(UseJava)

set(_find_jar_paths "")
set(_find_jar_version "")

if(${_cmff_NAME}_hints)
    list(APPEND _find_jar_paths "${_cmff_NAME}_hints")
    string(PREPEND _find_jar_paths "PATHS ")
endif()

if(${_cmff_NAME}_FIND_VERSION)
    set(_find_jar_version "VERSIONS ${${_cmff_NAME}_FIND_VERSION}")
endif()

find_jar(rr_jar_path rr.war
    ${_find_jar_paths}
    ${_find_jar_version}
    DOC "Railroad diagram generator"
)

# we will try to fetch content
if(NOT rr_jar_path)
    set(_try_fetch false)
    if(${_cmff_NAME}_FIND_VERSION)
        set(${_cmff_NAME}_KNOWN_VERSION 1.63)
        if(   (${_cmff_NAME}_FIND_VERSION_EXACT AND ${_cmff_NAME}_FIND_VERSION VERSION_EQUAL ${_cmff_NAME}_KNOWN_VERSION) 
           OR (NOT ${_cmff_NAME}_FIND_VERSION_EXACT AND  ${_cmff_NAME}_FIND_VERSION VERSION_LESS_EQUAL ${_cmff_NAME}_KNOWN_VERSION))
            set(_try_fetch true)
        endif()
    else()
        set(_try_fetch true)
    endif()

    if(_try_fetch)
        if(POLICY CMP0135)
            cmake_policy(PUSH)
            cmake_policy(SET CMP0135 NEW)
        endif()

        include(FetchContent)

        FetchContent_Declare(
            ${_cmff_NAME}_jar_package 
            URL "https://github.com/GuntherRademacher/rr/releases/download/v1.63/rr-1.63-java8.zip"
        )

        FetchContent_MakeAvailable(${_cmff_NAME}_jar_package)

        if(EXISTS ${rr_jar_package_SOURCE_DIR}/rr.war)
            set(rr_jar_path ${rr_jar_package_SOURCE_DIR}/rr.war)
            string(STRIP "${rr_jar_path}" rr_jar_path)
            set(rr_jar_path "${rr_jar_path}" CACHE FILEPATH "Path to rr war file" FORCE)
        endif()

        if(POLICY CMP0135)
            cmake_policy(POP)
        endif()
    endif()
endif()

if(rr_jar_path)
    set(${_cmff_NAME}_COMMAND "${Java_JAVA_EXECUTABLE};-jar;${rr_jar_path}" CACHE STRING "RR command")
endif()

# handle components, version, quiet, required and other flags ---------------- #
find_package_handle_standard_args(${_cmff_NAME}
    REQUIRED_VARS ${_cmff_NAME}_COMMAND
    FAIL_MESSAGE  "rr.war not found, installation: https://github.com/GuntherRademacher/rr/releases"
    HANDLE_COMPONENTS
)