# OpenPaw firmware top-level build
cmake_minimum_required(VERSION 3.16)

# Board selection: -DOPENPAW_BOARD=esp32_ball_v1|hw_v2|openpaw
if(NOT DEFINED OPENPAW_BOARD)
    set(OPENPAW_BOARD "esp32_ball_v1")
endif()
set(ENV{OPENPAW_BOARD} ${OPENPAW_BOARD})

include($ENV{IDF_PATH}/tools/cmake/project.cmake)
project(openpaw)
