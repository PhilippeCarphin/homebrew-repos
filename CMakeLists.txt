cmake_minimum_required(VERSION 3.16)

list(APPEND CMAKE_MODULE_PATH ${CMAKE_SOURCE_DIR}/cmake/modules)
list(APPEND CMAKE_MODULE_PATH ${CMAKE_SOURCE_DIR}/cmake/cmake-golang)
project(repos)

if("${CMAKE_INSTALL_PREFIX}" STREQUAL "/usr/local")
    set(CMAKE_INSTALL_PREFIX ${CMAKE_BINARY_DIR}/install-site CACHE FILEPATH "CMake Installation prefix for ${PROJECT_NAME}" FORCE)
    message(STATUS "Setting CMAKE_INSTALL_PREFIX to ${CMAKE_INSTALL_PREFIX}")
endif()


include(orgmanpages)
orgmanpages_add_man_target()

include(CTest)
add_custom_target(check COMMAND CTEST_OUTPUT_ON_FAILURE=true ${CMAKE_CTEST_COMMAND})
install(PROGRAMS scripts/git-recent DESTINATION bin)
install(PROGRAMS scripts/repo_finder.py DESTINATION bin RENAME repo-finder)

set(repos_exec ${CMAKE_BINARY_DIR}/repos)
add_custom_command(
    OUTPUT repos
    COMMAND cd ${CMAKE_SOURCE_DIR}/src && go build -o ${CMAKE_BINARY_DIR}/repos main.go
    DEPENDS src/main.go
)

add_custom_target(build-repos ALL DEPENDS repos)

install(PROGRAMS ${repos_exec} DESTINATION bin)
