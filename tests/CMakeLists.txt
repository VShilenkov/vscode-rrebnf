cmake_minimum_required(VERSION 3.16)

find_package(RR)

include(UseRR)

add_rr(target_hyarget
    SOURCES rr.include.ebnf
    DESTINATION ${CMAKE_BINARY_DIR}/rr
)

add_subdirectory(cxx-std)