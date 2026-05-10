cmake_minimum_required(VERSION 3.22.1)
project(offline_ai_buddy)

# Path to vendored llama.cpp source. The submodule must be initialized
# (`git submodule update --init --recursive`) before this builds.
set(LLAMA_CPP_DIR ${CMAKE_SOURCE_DIR}/../../../../vendor/llama.cpp)

if(EXISTS ${LLAMA_CPP_DIR}/CMakeLists.txt)
    set(LLAMA_BUILD_TESTS OFF CACHE BOOL "" FORCE)
    set(LLAMA_BUILD_EXAMPLES OFF CACHE BOOL "" FORCE)
    set(LLAMA_BUILD_SERVER OFF CACHE BOOL "" FORCE)
    add_subdirectory(${LLAMA_CPP_DIR} llama.cpp)

    add_library(offline_ai_buddy SHARED llama_jni.cpp)
    target_link_libraries(offline_ai_buddy llama log)
else()
    # Submodule not present — build a stub library so the Kotlin
    # `LlamaJni` external functions still link (they'll throw at
    # runtime). CI without the submodule still compiles.
    add_library(offline_ai_buddy SHARED llama_jni_stub.cpp)
    find_library(log-lib log)
    target_link_libraries(offline_ai_buddy ${log-lib})
endif()
