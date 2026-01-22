# miniaudio_ffi - Flutter FFI plugin for low-latency audio
# Cross-platform miniaudio wrapper with pull-mode (callback) support

cmake_minimum_required(VERSION 3.10)

project(miniaudio_ffi_library VERSION 1.0.0 LANGUAGES C)

# Source files
add_library(miniaudio_ffi SHARED
  "miniaudio_bridge.c"
)

set_target_properties(miniaudio_ffi PROPERTIES
  PUBLIC_HEADER "miniaudio_bridge.h"
  OUTPUT_NAME "miniaudio_ffi"
)

target_compile_definitions(miniaudio_ffi PUBLIC DART_SHARED_LIB)

# Platform-specific settings
if(ANDROID)
  # Android: Link log and OpenSL ES (fallback)
  find_library(log-lib log)
  find_library(opensles-lib OpenSLES)
  target_link_libraries(miniaudio_ffi ${log-lib})
  if(opensles-lib)
    target_link_libraries(miniaudio_ffi ${opensles-lib})
  endif()
  # Support Android 15 16k page size
  target_link_options(miniaudio_ffi PRIVATE "-Wl,-z,max-page-size=16384")

elseif(APPLE)
  # iOS/macOS: Link AudioToolbox and CoreAudio
  find_library(AUDIOTOOLBOX_LIBRARY AudioToolbox)
  find_library(COREAUDIO_LIBRARY CoreAudio)
  find_library(COREFOUNDATION_LIBRARY CoreFoundation)
  target_link_libraries(miniaudio_ffi 
    ${AUDIOTOOLBOX_LIBRARY} 
    ${COREAUDIO_LIBRARY}
    ${COREFOUNDATION_LIBRARY}
  )

elseif(WIN32)
  # Windows: Link ole32 for WASAPI
  target_link_libraries(miniaudio_ffi ole32 winmm)

elseif(UNIX)
  # Linux: Link pthread, m, dl for ALSA/PulseAudio
  find_package(Threads REQUIRED)
  target_link_libraries(miniaudio_ffi 
    Threads::Threads 
    m 
    dl
  )
endif()

# Compiler flags
target_compile_options(miniaudio_ffi PRIVATE
  -Wall
  -O2
)
