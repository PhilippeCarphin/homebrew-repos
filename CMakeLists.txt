cmake_minimum_required(VERSION 3.11)

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

if(SSM_PACKAGE_NAME)
    install(FILES completions/repos_completion.bash DESTINATION etc/profile.d/ RENAME ${SSM_PACKAGE_NAME}.sh)
endif()

set(repos_exec ${CMAKE_BINARY_DIR}/repos)
add_custom_command(
    OUTPUT repos
    COMMAND cd ${CMAKE_SOURCE_DIR}/src && go build -o ${CMAKE_BINARY_DIR}/repos main.go
    DEPENDS src/main.go
)

add_custom_target(build-repos ALL DEPENDS repos)

configure_file(modulefile.in modulefile @ONLY)
install(FILES ${CMAKE_BINARY_DIR}/modulefile DESTINATION $ENV{HOME}/privatemodules RENAME repos)
install(PROGRAMS ${repos_exec} DESTINATION bin)
install(DIRECTORY bin/ DESTINATION bin USE_SOURCE_PERMISSIONS)
install(
    DIRECTORY libexec/
    DESTINATION libexec
    USE_SOURCE_PERMISSIONS
    PATTERN __pycache__ EXCLUDE
)

install(
    FILES
        completions/repos_completion.bash
    DESTINATION
        etc/bash_completion.d
)
install(
    FILES
        completions/repos_completion.fish
    DESTINATION
        etc/fish_completion.d
)
install(
    FILES
        completions/repos_completion.zsh
    DESTINATION
        etc/zsh_completion.d
)

# --no-track prevents the creation of .json files with package info
# --force overwrites files if they are already there
install(CODE
    "execute_process(COMMAND cargo install --path ${CMAKE_SOURCE_DIR}/rust/repos-add --root ${CMAKE_INSTALL_PREFIX} --no-track --force)"
)
