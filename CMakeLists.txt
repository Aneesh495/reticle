cmake_minimum_required(VERSION 3.16)
project(reticle VERSION 1.0.0 LANGUAGES C)

set(CMAKE_C_STANDARD 17)
set(CMAKE_C_STANDARD_REQUIRED ON)
set(CMAKE_POSITION_INDEPENDENT_CODE ON)

include_directories(include)

add_library(reticle_fastpath SHARED
    src/fastpath.c
)

target_include_directories(reticle_fastpath PUBLIC
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
    $<INSTALL_INTERFACE:include>
)

enable_testing()

if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/tests/test_fastpath.c")
    add_executable(test_fastpath tests/test_fastpath.c)
    target_link_libraries(test_fastpath PRIVATE reticle_fastpath)
    add_test(NAME fastpath_unit_tests COMMAND test_fastpath)
endif()
