cmake_minimum_required(VERSION 3.17)
project(tests LANGUAGES C)

set(CMAKE_C_STANDARD 99)

set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -fsanitize=address -fsanitize=undefined -Wall -Wextra -pedantic -Werror")
set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -fsanitize=address -fsanitize=undefined")

if (IS_DIRECTORY ${STUDENT_DIR})
    set(STUDENT_SOURCE_DIR "${STUDENT_DIR}/src")
    add_subdirectory(${STUDENT_SOURCE_DIR})
else()
    message(FATAL_ERROR "${STUDENT_DIR} is not directory")
endif()
