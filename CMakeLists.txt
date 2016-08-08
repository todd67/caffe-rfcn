cmake_minimum_required(VERSION 2.8.7)

# ---[ Caffe project
project(Caffe C CXX)

# ---[ Caffe version
set(CAFFE_TARGET_VERSION "1.0.0-rc3")
set(CAFFE_TARGET_SOVERSION "1.0.0-rc3")
add_definitions(-DCAFFE_VERSION=${CAFFE_TARGET_VERSION})

set(3RDPARTY_DIR ${PROJECT_SOURCE_DIR}/3rdparty)

# Optionally force a certain CUDA toolkit path
set(CUDA_TOOLKIT_ROOT_DIR /usr/local/cuda-7.5)

# ---[ Using cmake scripts and modules
list(APPEND CMAKE_MODULE_PATH ${PROJECT_SOURCE_DIR}/cmake/Modules)

include(ExternalProject)

include(cmake/Utils.cmake)
include(cmake/Targets.cmake)
include(cmake/Misc.cmake)
include(cmake/Summary.cmake)
include(cmake/ConfigGen.cmake)

# ---[ Options
caffe_option(CPU_ONLY  "Build Caffe without CUDA support" OFF) # TODO: rename to USE_CUDA
caffe_option(USE_CUDNN "Build Caffe with cuDNN library support" ON IF NOT CPU_ONLY)
caffe_option(BUILD_SHARED_LIBS "Build shared libraries" ON)
caffe_option(BUILD_python "Build Python wrapper" ON)
set(python_version "2" CACHE STRING "Specify which Python version to use")
caffe_option(BUILD_matlab "Build Matlab wrapper" ON)  # OFF IF UNIX OR APPLE
caffe_option(BUILD_docs   "Build documentation" OFF IF UNIX OR APPLE)
caffe_option(BUILD_python_layer "Build the Caffe Python layer" ON)
caffe_option(USE_OPENCV "Build with OpenCV support" ON)
caffe_option(USE_LEVELDB "Build with levelDB" OFF)
caffe_option(USE_LMDB "Build with lmdb" ON)
caffe_option(ALLOW_LMDB_NOLOCK "Allow MDB_NOLOCK when reading LMDB files (only if necessary)" OFF)

if(BUILD_matlab)
  set(Matlab_DIR "/usr/local/MATLAB/R2014a")
endif()

# ---[ Using C++11
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++11")

# ---[ Dependencies
include(cmake/Dependencies.cmake)

# ---[ Flags
if(UNIX OR APPLE)
  set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fPIC -Wall")
endif()

caffe_set_caffe_link()

if(USE_libstdcpp)
  set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -stdlib=libstdc++")
  message("-- Warning: forcing libstdc++ (controlled by USE_libstdcpp option in cmake)")
endif()

add_definitions(-DGTEST_USE_OWN_TR1_TUPLE)

# ---[ Warnings
caffe_warnings_disable(CMAKE_CXX_FLAGS -Wno-sign-compare -Wno-uninitialized -Wunused-local-typedefs)

# ---[ Config generation
configure_file(cmake/Templates/caffe_config.h.in "${PROJECT_BINARY_DIR}/caffe_config.h")

# ---[ Includes
set(Caffe_INCLUDE_DIR ${PROJECT_SOURCE_DIR}/include)
include_directories(${Caffe_INCLUDE_DIR} ${PROJECT_BINARY_DIR})
include_directories(BEFORE src) # This is needed for gtest.

# ---[ Subdirectories
add_subdirectory(src/gtest)
add_subdirectory(src/caffe)
add_subdirectory(tools)
add_subdirectory(examples)
add_subdirectory(python)
add_subdirectory(matlab)
add_subdirectory(docs)

# ---[ Linter target
add_custom_target(lint COMMAND ${CMAKE_COMMAND} -P ${PROJECT_SOURCE_DIR}/cmake/lint.cmake)

# ---[ pytest target
if(BUILD_python)
add_custom_target(pytest COMMAND python${python_version} -m unittest discover -s caffe/test WORKING_DIRECTORY ${PROJECT_SOURCE_DIR}/python )
add_dependencies(pytest pycaffe)
endif()

# ---[ Configuration summary
caffe_print_configuration_summary()

# ---[ Export configs generation
caffe_generate_export_configs()
