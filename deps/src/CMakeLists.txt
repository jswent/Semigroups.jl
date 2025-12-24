cmake_minimum_required(VERSION 3.15)
project(libsemigroups_julia CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

# Find JlCxx (CxxWrap C++ library)
find_package(JlCxx REQUIRED)

# Find libsemigroups via pkg-config
find_package(PkgConfig REQUIRED)
pkg_check_modules(LIBSEMIGROUPS REQUIRED libsemigroups)

message(STATUS "JlCxx found at: ${JlCxx_DIR}")
message(STATUS "libsemigroups include dirs: ${LIBSEMIGROUPS_INCLUDE_DIRS}")
message(STATUS "libsemigroups library dirs: ${LIBSEMIGROUPS_LIBRARY_DIRS}")
message(STATUS "libsemigroups libraries: ${LIBSEMIGROUPS_LIBRARIES}")

# Build the shared library
add_library(libsemigroups_julia SHARED
    libsemigroups_julia.cpp
    constants.cpp
    errors.cpp
)

# Include directories
target_include_directories(libsemigroups_julia PRIVATE
    ${LIBSEMIGROUPS_INCLUDE_DIRS}
)

# Link directories
target_link_directories(libsemigroups_julia PRIVATE
    ${LIBSEMIGROUPS_LIBRARY_DIRS}
)

# Link libraries
target_link_libraries(libsemigroups_julia
    JlCxx::cxxwrap_julia
    ${LIBSEMIGROUPS_LIBRARIES}
)

# Compiler flags from pkg-config
target_compile_options(libsemigroups_julia PRIVATE
    ${LIBSEMIGROUPS_CFLAGS_OTHER}
)

# Set output name - removes the extra "lib" prefix CMake would add
set_target_properties(libsemigroups_julia PROPERTIES
    PREFIX ""
    OUTPUT_NAME "libsemigroups_julia"
)

# Installation rules
install(TARGETS libsemigroups_julia
    LIBRARY DESTINATION lib
    ARCHIVE DESTINATION lib
)
