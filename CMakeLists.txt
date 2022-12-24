cmake_minimum_required(VERSION 3.16)
project(vscode-rrebnf VERSION 0.0.3)

list(APPEND CMAKE_MODULE_PATH ${CMAKE_CURRENT_LIST_DIR}/cmake)
message(STATUS "${CMAKE_MODULE_PATH}")

add_subdirectory(tests)