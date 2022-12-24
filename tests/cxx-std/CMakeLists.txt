cmake_minimum_required(VERSION 3.16)

find_package(RR)

include(UseRR)

add_rr(cxx-std
    SOURCES expr/primary.expression.ebnf
    DESTINATION ${CMAKE_BINARY_DIR}/rr/cxx
)

