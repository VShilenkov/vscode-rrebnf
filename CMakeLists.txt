cmake_minimum_required(VERSION 3.16)
project(vscode-rrebnf VERSION 0.0.3)

list(APPEND CMAKE_MODULE_PATH ${CMAKE_CURRENT_LIST_DIR}/cmake)
message(STATUS "${CMAKE_MODULE_PATH}")
find_package(RR)

include(UseRR)

generate_rr(
    SOURCES tests/rr.include.ebnf tests/rr.syntax.ebnf
    DESTINATION ${CMAKE_BINARY_DIR}/rr
    INCLUDE_DIRECTORIES tests
)