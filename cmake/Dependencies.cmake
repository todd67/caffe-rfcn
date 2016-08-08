# This list is required for static linking and exported to CaffeConfig.cmake
set(Caffe_LINKER_LIBS "")

# add 3rdparty run time dir
link_directories(${PROJECT_BINARY_DIR})

# ---[ Boost
#find_package(Boost 1.46 REQUIRED COMPONENTS system thread)
#include_directories(SYSTEM ${Boost_INCLUDE_DIR})
#list(APPEND Caffe_LINKER_LIBS ${Boost_LIBRARIES})

# use 3rdparty boost
set(3RDPARTY_BOOST_DIR ${3RDPARTY_DIR}/boost_1_49)
set(Boost_INCLUDE_DIRS ${3RDPARTY_BOOST_DIR}/include)
set(Boost_INCLUDE_DIR ${3RDPARTY_BOOST_DIR}/include)
set(Boost_MAJOR_VERSION 1.49)
set(Boost_MINOR_VERSION 0)
set(Boost_VERSION 104900)
set(boost_version_suffix 1.49.0)
set(icu_version_suffix 49)
include_directories(${3RDPARTY_BOOST_DIR}/include)
set(boost_component system thread)

if(BUILD_python)
  set(boost_component ${boost_component} python)
  if(BUILD_python_layer)
    set(boost_component ${boost_component} regex)
  endif()
endif()

foreach(component ${boost_component})
  configure_file("${3RDPARTY_BOOST_DIR}/lib/libboost_${component}.so.${boost_version_suffix}"
                 "${PROJECT_BINARY_DIR}/libboost_${component}.so.${boost_version_suffix}" COPYONLY)
  execute_process(COMMAND ln -s -f
                  "libboost_${component}.so.${boost_version_suffix}" "libboost_${component}.so"
                  WORKING_DIRECTORY ${PROJECT_BINARY_DIR})
  set(Boost_LIBRARIES ${Boost_LIBRARIES} "boost_${component}")
endforeach()

# libicu for boost
configure_file("${3RDPARTY_BOOST_DIR}/lib/libicuuc.so.${icu_version_suffix}"
		"${PROJECT_BINARY_DIR}/libicuuc.so.${icu_version_suffix}" COPYONLY)
configure_file("${3RDPARTY_BOOST_DIR}/lib/libicui18n.so.${icu_version_suffix}"
		"${PROJECT_BINARY_DIR}/libicui18n.so.${icu_version_suffix}" COPYONLY)
configure_file("${3RDPARTY_BOOST_DIR}/lib/libicudata.so.${icu_version_suffix}"
		"${PROJECT_BINARY_DIR}/libicudata.so.${icu_version_suffix}" COPYONLY)

if(BUILD_python)
  set(Boost_PYTHON_FOUND 1)
  if(BUILD_python_layer)
    set(Boost_REGEX_FOUND 1)
  endif()
endif()

list(APPEND Caffe_LINKER_LIBS ${Boost_LIBRARIES})

# ---[ Threads
find_package(Threads REQUIRED)
list(APPEND Caffe_LINKER_LIBS ${CMAKE_THREAD_LIBS_INIT})

# ---[ Google-glog
include("cmake/External/glog.cmake")
include_directories(SYSTEM ${GLOG_INCLUDE_DIRS})
list(APPEND Caffe_LINKER_LIBS ${GLOG_LIBRARIES})

# ---[ Google-gflags
include("cmake/External/gflags.cmake")
include_directories(SYSTEM ${GFLAGS_INCLUDE_DIRS})
list(APPEND Caffe_LINKER_LIBS ${GFLAGS_LIBRARIES})

# ---[ Google-protobuf
include(cmake/ProtoBuf.cmake)

# ---[ HDF5
#find_package(HDF5 COMPONENTS HL REQUIRED)
#include_directories(SYSTEM ${HDF5_INCLUDE_DIRS} ${HDF5_HL_INCLUDE_DIR})
#list(APPEND Caffe_LINKER_LIBS ${HDF5_LIBRARIES})
# use 3rdparty hdf5 to align with MATLAB R2014a
set(3RDPARTY_HDF5_DIR ${3RDPARTY_DIR}/hdf5_1.8.6)
include_directories(${3RDPARTY_HDF5_DIR}/include)
configure_file(${3RDPARTY_HDF5_DIR}/lib/libhdf5.so.1.8.6 ${PROJECT_BINARY_DIR}/libhdf5.so.1.8.6 COPYONLY)
configure_file(${3RDPARTY_HDF5_DIR}/lib/libhdf5_hl.so.1.8.6 ${PROJECT_BINARY_DIR}/libhdf5_hl.so.1.8.6 COPYONLY)
execute_process(COMMAND ln -s -f libhdf5.so.1.8.6 libhdf5.so WORKING_DIRECTORY ${PROJECT_BINARY_DIR})
execute_process(COMMAND ln -s -f libhdf5_hl.so.1.8.6 libhdf5_hl.so WORKING_DIRECTORY ${PROJECT_BINARY_DIR})
set(HDF5_LIBRARIES hdf5 hdf5_hl)
list(APPEND Caffe_LINKER_LIBS ${HDF5_LIBRARIES})

# ---[ LMDB
if(USE_LMDB)
  find_package(LMDB REQUIRED)
  include_directories(SYSTEM ${LMDB_INCLUDE_DIR})
  list(APPEND Caffe_LINKER_LIBS ${LMDB_LIBRARIES})
  add_definitions(-DUSE_LMDB)
  if(ALLOW_LMDB_NOLOCK)
    add_definitions(-DALLOW_LMDB_NOLOCK)
  endif()
endif()

# ---[ LevelDB
if(USE_LEVELDB)
#  find_package(LevelDB REQUIRED)
#  include_directories(SYSTEM ${LevelDB_INCLUDE})

  # use 3rdparty level db
  set(3RDPARTY_LEVELDB_DIR ${3RDPARTY_DIR}/leveldb-1.15.0)
  include_directories(${3RDPARTY_LEVELDB_DIR}/include)
  link_directories(${3RDPARTY_LEVELDB_DIR}/lib)
  set(LevelDB_LIBRARIES leveldb)
  list(APPEND Caffe_LINKER_LIBS ${LevelDB_LIBRARIES})
  add_definitions(-DUSE_LEVELDB)
endif()

# ---[ Snappy
if(USE_LEVELDB)
  #find_package(Snappy REQUIRED)
  #include_directories(SYSTEM ${Snappy_INCLUDE_DIR})
  #list(APPEND Caffe_LINKER_LIBS ${Snappy_LIBRARIES})

  # use 3rdparty snappy
  set(3RDPARTY_SNAPPY_DIR ${3RDPARTY_DIR}/snappy-1.1.2)
  include_directories(${3RDPARTY_SNAPPY_DIR}/include)
  link_directories(${3RDPARTY_SNAPPY_DIR}/lib)
  set(Snappy_LIBRARIES snappy)
  list(APPEND Caffe_LINKER_LIBS ${LevelDB_LIBRARIES})
endif()

# ---[ CUDA
include(cmake/Cuda.cmake)
if(NOT HAVE_CUDA)
  if(CPU_ONLY)
    message(STATUS "-- CUDA is disabled. Building without it...")
  else()
    message(WARNING "-- CUDA is not detected by cmake. Building without it...")
  endif()

  # TODO: remove this not cross platform define in future. Use caffe_config.h instead.
  add_definitions(-DCPU_ONLY)
endif()

# ---[ OpenCV
if(USE_OPENCV)
#  find_package(OpenCV QUIET COMPONENTS core highgui imgproc imgcodecs)
#  if(NOT OpenCV_FOUND) # if not OpenCV 3.x, then imgcodecs are not found
#    find_package(OpenCV REQUIRED COMPONENTS core highgui imgproc)
#  endif()
#  include_directories(SYSTEM ${OpenCV_INCLUDE_DIRS})
#  list(APPEND Caffe_LINKER_LIBS ${OpenCV_LIBS})
#  message(STATUS "OpenCV found (${OpenCV_CONFIG_PATH})")
#  add_definitions(-DUSE_OPENCV)

# use opencv from 3rdparty to align with MATLAB R2014a
  set(3RDPARTY_OPENCV_DIR ${3RDPARTY_DIR}/opencv-2.4.11)
  message(STATUS "Found opencv in ${3RDPARTY_OPENCV_DIR}")
  include_directories(${3RDPARTY_OPENCV_DIR}/include)
  link_directories(${3RDPARTY_OPENCV_DIR}/lib)
  link_directories(${3RDPARTY_OPENCV_DIR}/share/OpenCV/3rdparty/lib)
  list(APPEND Caffe_LINKER_LIBS opencv_imgproc opencv_highgui opencv_core
    tiff jasper jpeg png gif z)
  add_definitions(-DUSE_OPENCV)
endif()

# ---[ BLAS
if(NOT APPLE)
  set(BLAS "MKL" CACHE STRING "Selected BLAS library")
  set_property(CACHE BLAS PROPERTY STRINGS "Atlas;Open;MKL")

  if(BLAS STREQUAL "Atlas" OR BLAS STREQUAL "atlas")
    find_package(Atlas REQUIRED)
    include_directories(SYSTEM ${Atlas_INCLUDE_DIR})
    list(APPEND Caffe_LINKER_LIBS ${Atlas_LIBRARIES})
  elseif(BLAS STREQUAL "Open" OR BLAS STREQUAL "open")
    find_package(OpenBLAS REQUIRED)
    include_directories(SYSTEM ${OpenBLAS_INCLUDE_DIR})
    list(APPEND Caffe_LINKER_LIBS ${OpenBLAS_LIB})
  elseif(BLAS STREQUAL "MKL" OR BLAS STREQUAL "mkl")
    find_package(MKL REQUIRED)
    include_directories(SYSTEM ${MKL_INCLUDE_DIR})
    list(APPEND Caffe_LINKER_LIBS ${MKL_LIBRARIES})
    # must link against iomp
    list(APPEND Caffe_LINKER_LIBS /opt/intel/lib/intel64/libiomp5.so)
    add_definitions(-DUSE_MKL)
  endif()
elseif(APPLE)
  find_package(vecLib REQUIRED)
  include_directories(SYSTEM ${vecLib_INCLUDE_DIR})
  list(APPEND Caffe_LINKER_LIBS ${vecLib_LINKER_LIBS})
endif()

# ---[ Python
if(BUILD_python)
  if(NOT "${python_version}" VERSION_LESS "3.0.0")
    # use python3
    find_package(PythonInterp 3.0)
    find_package(PythonLibs 3.0)
    find_package(NumPy 1.7.1)
    # Find the matching boost python implementation
    set(version ${PYTHONLIBS_VERSION_STRING})    
  else()
    # disable Python 3 search
    find_package(PythonInterp 2.7)
    find_package(PythonLibs 2.7)
    find_package(NumPy 1.7.1)
  endif()
  if(PYTHONLIBS_FOUND AND NUMPY_FOUND AND Boost_PYTHON_FOUND)
    set(HAVE_PYTHON TRUE)
    if(BUILD_python_layer)
      add_definitions(-DWITH_PYTHON_LAYER)
      include_directories(SYSTEM ${PYTHON_INCLUDE_DIRS} ${NUMPY_INCLUDE_DIR} ${Boost_INCLUDE_DIRS})
      list(APPEND Caffe_LINKER_LIBS ${PYTHON_LIBRARIES} ${Boost_LIBRARIES})
    endif()
  endif()
endif()

# ---[ Matlab
if(BUILD_matlab)
  find_package(MatlabMex)
  if(MATLABMEX_FOUND)
    set(HAVE_MATLAB TRUE)
  endif()

  # sudo apt-get install liboctave-dev
  find_program(Octave_compiler NAMES mkoctfile DOC "Octave C++ compiler")

  if(HAVE_MATLAB AND Octave_compiler)
    set(Matlab_build_mex_using "Matlab" CACHE STRING "Select Matlab or Octave if both detected")
    set_property(CACHE Matlab_build_mex_using PROPERTY STRINGS "Matlab;Octave")
  endif()
endif()

# ---[ Doxygen
if(BUILD_docs)
  find_package(Doxygen)
endif()
