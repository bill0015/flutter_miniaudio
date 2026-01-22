/*
 * miniaudio_bridge.h - FFI Bridge for Flutter miniaudio plugin
 * 
 * Provides a simple C API for:
 * - Initializing low-latency audio playback
 * - Setting up shared memory FIFO for Dart ↔ Native communication
 * - Pull-mode audio via miniaudio data_callback
 */

#ifndef MINIAUDIO_BRIDGE_H
#define MINIAUDIO_BRIDGE_H

#include <stdint.h>
#include <stddef.h>

#ifdef _WIN32
    #define MA_BRIDGE_EXPORT __declspec(dllexport)
#else
    #define MA_BRIDGE_EXPORT __attribute__((visibility("default")))
#endif

#ifdef __cplusplus
extern "C" {
#endif

/**
 * Initialize the audio device.
 * @param sample_rate  Audio sample rate (e.g., 44100, 48000)
 * @param channels     Number of channels (1 = mono, 2 = stereo)
 * @param buffer_frames Period size in frames (lower = lower latency)
 * @return 0 on success, -1 on failure
 */
MA_BRIDGE_EXPORT int ma_bridge_init(int sample_rate, int channels, int buffer_frames);

/**
 * Set the shared FIFO buffer for Dart ↔ Native communication.
 * Dart allocates memory and passes pointers here.
 * @param fifo_ptr       Pointer to FIFO buffer (int16_t samples, interleaved stereo)
 * @param capacity_samples Total capacity in samples (frames * channels)
 * @param read_pos       Pointer to read position (atomic, updated by native)
 * @param write_pos      Pointer to write position (atomic, updated by Dart)
 */
MA_BRIDGE_EXPORT void ma_bridge_set_fifo(
    int16_t* fifo_ptr, 
    int capacity_samples, 
    volatile int* read_pos, 
    volatile int* write_pos
);

/**
 * Start audio playback.
 * @return 0 on success, -1 on failure
 */
MA_BRIDGE_EXPORT int ma_bridge_start(void);

/**
 * Stop audio playback.
 * @return 0 on success, -1 on failure
 */
MA_BRIDGE_EXPORT int ma_bridge_stop(void);

/**
 * Get the total number of frames consumed by the audio device.
 * Used for synchronization calculations in Dart.
 * @return Total frames consumed since start
 */
MA_BRIDGE_EXPORT uint64_t ma_bridge_get_frames_consumed(void);

/**
 * Get current FIFO fill level in samples.
 * @return Number of samples available in FIFO
 */
MA_BRIDGE_EXPORT int32_t ma_bridge_get_fifo_available(void);

// Advanced Controls
MA_BRIDGE_EXPORT void ma_bridge_set_volume(float volume); // 0.0 to 1.0 (or higher for gain)
MA_BRIDGE_EXPORT int32_t ma_bridge_get_device_sample_rate(void); // Get actual hardware sample rate
MA_BRIDGE_EXPORT int32_t ma_bridge_get_device_channels(void); // Get actual hardware channels

// --- Device Enumeration (Context) ---

/**
 * Get device count.
 * @param type 0 = Playback, 1 = Capture.
 */
MA_BRIDGE_EXPORT int32_t ma_bridge_context_get_device_count(int32_t type);

/**
 * Get device info at index.
 * @param type 0 = Playback, 1 = Capture.
 * @param index Device index.
 * @param name_buffer Buffer to store device name (utf8).
 * @param name_len Size of name buffer.
 * @param id_buffer Buffer to store device ID (ma_device_id, usually bytes).
 * @param id_len Size of id buffer (sizeof(ma_device_id)).
 */
MA_BRIDGE_EXPORT int32_t ma_bridge_context_get_device_info(int32_t type, int32_t index, char* name_buffer, int32_t name_len, void* id_buffer, int32_t id_len);

// --- Device API (Low Level) ---

/**
 * Initialize the audio device with optional device ID.
 * @param device_id Pointer to ma_device_id (can be NULL for default).
 */
MA_BRIDGE_EXPORT int ma_bridge_init_with_device_id(void* device_id, int sample_rate, int channels, int buffer_frames);

// ... (Existing start/stop/read/write/volume APIs for device remain) ...

// --- Engine API (High Level) ---

/**
 * Initialize the high-level audio engine.
 * @return 0 on success.
 */
MA_BRIDGE_EXPORT int ma_bridge_engine_init(void);

MA_BRIDGE_EXPORT void ma_bridge_engine_uninit(void);

MA_BRIDGE_EXPORT int ma_bridge_engine_start(void);
MA_BRIDGE_EXPORT int ma_bridge_engine_stop(void);
MA_BRIDGE_EXPORT void ma_bridge_engine_set_volume(float volume);

/**
 * Play a sound one-shot (fire and forget).
 * @param path File path.
 */
MA_BRIDGE_EXPORT void ma_bridge_engine_play_sound(const char* path);

// --- Sound Object API ---

/** 
 * Create/Load a sound.
 * @return Sound Handle (pointer or ID). Returns 0/NULL on failure.
 */
MA_BRIDGE_EXPORT void* ma_bridge_sound_init_from_file(const char* path, int32_t flags);
MA_BRIDGE_EXPORT void* ma_bridge_sound_init_from_file_with_group(const char* path, void* group_handle, int32_t flags);

MA_BRIDGE_EXPORT void ma_bridge_sound_uninit(void* sound_handle);

MA_BRIDGE_EXPORT void ma_bridge_sound_play(void* sound_handle);
MA_BRIDGE_EXPORT void ma_bridge_sound_stop(void* sound_handle);
MA_BRIDGE_EXPORT void ma_bridge_sound_set_volume(void* sound_handle, float volume);
MA_BRIDGE_EXPORT void ma_bridge_sound_set_pitch(void* sound_handle, float pitch);
MA_BRIDGE_EXPORT void ma_bridge_sound_set_pan(void* sound_handle, float pan);
MA_BRIDGE_EXPORT void ma_bridge_sound_set_looping(void* sound_handle, int32_t loop);
MA_BRIDGE_EXPORT void ma_bridge_sound_set_position(void* sound_handle, float x, float y, float z);
MA_BRIDGE_EXPORT void ma_bridge_sound_set_direction(void* sound_handle, float x, float y, float z);
MA_BRIDGE_EXPORT void ma_bridge_sound_set_velocity(void* sound_handle, float x, float y, float z);
MA_BRIDGE_EXPORT void ma_bridge_sound_set_cone(void* sound_handle, float innerAngle, float outerAngle, float outerGain);
MA_BRIDGE_EXPORT void ma_bridge_sound_set_doppler_factor(void* sound_handle, float factor);

// --- Listener API ---
MA_BRIDGE_EXPORT void ma_bridge_engine_listener_set_position(int32_t listenerIndex, float x, float y, float z);
MA_BRIDGE_EXPORT void ma_bridge_engine_listener_set_direction(int32_t listenerIndex, float x, float y, float z);
MA_BRIDGE_EXPORT void ma_bridge_engine_listener_set_velocity(int32_t listenerIndex, float x, float y, float z);
MA_BRIDGE_EXPORT void ma_bridge_engine_listener_set_world_up(int32_t listenerIndex, float x, float y, float z);
MA_BRIDGE_EXPORT void ma_bridge_engine_listener_set_cone(int32_t listenerIndex, float innerAngle, float outerAngle, float outerGain);
MA_BRIDGE_EXPORT void ma_bridge_engine_listener_set_enabled(int32_t listenerIndex, int32_t enabled);

MA_BRIDGE_EXPORT void ma_bridge_sound_set_fade_in_pcm_frames(void* sound_handle, float volumeBeg, float volumeEnd, uint64_t len);
MA_BRIDGE_EXPORT void ma_bridge_sound_set_fade_start_time(void* sound_handle, float volumeBeg, float volumeEnd, uint64_t len, uint64_t absoluteGlobalTime);

MA_BRIDGE_EXPORT void ma_bridge_sound_seek_to_pcm_frame(void* sound_handle, uint64_t frameIndex);
MA_BRIDGE_EXPORT uint64_t ma_bridge_sound_get_length_in_pcm_frames(void* sound_handle);
MA_BRIDGE_EXPORT uint64_t ma_bridge_sound_get_cursor_in_pcm_frames(void* sound_handle); // Current position

MA_BRIDGE_EXPORT int32_t ma_bridge_sound_is_playing(void* sound_handle);
MA_BRIDGE_EXPORT int32_t ma_bridge_sound_at_end(void* sound_handle);
// --- Sound Group API ---
MA_BRIDGE_EXPORT void* ma_bridge_sound_group_init(void* parent_group_handle); // Pass NULL to attach to engine master
MA_BRIDGE_EXPORT void ma_bridge_sound_group_uninit(void* group_handle);
MA_BRIDGE_EXPORT void ma_bridge_sound_group_start(void* group_handle);
MA_BRIDGE_EXPORT void ma_bridge_sound_group_stop(void* group_handle);
MA_BRIDGE_EXPORT void ma_bridge_sound_group_set_volume(void* group_handle, float volume);
MA_BRIDGE_EXPORT void ma_bridge_sound_group_set_pan(void* group_handle, float pan);
MA_BRIDGE_EXPORT void ma_bridge_sound_group_set_pitch(void* group_handle, float pitch);

/**
 * Load sound from memory buffer.
 * @param data Pointer to audio data (MP3/WAV/etc).
 * @param size Size of buffer in bytes.
 * @return Sound Handle.
 */
MA_BRIDGE_EXPORT void* ma_bridge_sound_init_from_memory(const void* data, size_t size, int32_t flags);


// --- Generation ---

/**
 * Create a noise sound.
 * @param type 0=White, 1=Pink, 2=Brownian.
 * @param amplitude 0.0 to 1.0.
 * @param seed Random seed.
 * @return Sound Handle.
 */
MA_BRIDGE_EXPORT void* ma_bridge_sound_init_noise(int32_t type, float amplitude, int32_t seed);

/**
 * Create a waveform sound.
 * @param type 0=Sine, 1=Square, 2=Triangle, 3=Sawtooth.
 * @param amplitude 0.0 to 1.0.
 * @param frequency Hz.
 * @return Sound Handle.
 */
MA_BRIDGE_EXPORT void* ma_bridge_sound_init_waveform(int32_t type, float amplitude, double frequency);


// --- Effects & Graph (Node System) ---

/**
 * Base Node Handle.
 * All effect functions take this handle.
 */

// Delay Node
MA_BRIDGE_EXPORT void* ma_bridge_node_delay_init(void);
MA_BRIDGE_EXPORT void ma_bridge_node_delay_set_delay(void* node_handle, float delayInSeconds);
MA_BRIDGE_EXPORT void ma_bridge_node_delay_set_wet(void* node_handle, float wet); // 0..1 (mix)
MA_BRIDGE_EXPORT void ma_bridge_node_delay_set_dry(void* node_handle, float dry); // 0..1
MA_BRIDGE_EXPORT void ma_bridge_node_delay_set_decay(void* node_handle, float decay); // 0..1 (feedback)

// Reverb Node
MA_BRIDGE_EXPORT void* ma_bridge_node_reverb_init(void);
MA_BRIDGE_EXPORT void ma_bridge_node_reverb_set_params(void* node_handle, float roomSize, float damping, float width, float wet, float dry);

// LPF (Low Pass Filter) Node
MA_BRIDGE_EXPORT void* ma_bridge_node_lpf_init(void);
MA_BRIDGE_EXPORT void ma_bridge_node_lpf_set_cutoff(void* node_handle, float cutoffFrequency);

// HPF (High Pass Filter) Node
MA_BRIDGE_EXPORT void* ma_bridge_node_hpf_init(void);
MA_BRIDGE_EXPORT void ma_bridge_node_hpf_set_cutoff(void* node_handle, float cutoffFrequency);

// Peaking EQ Node (Band EQ)
MA_BRIDGE_EXPORT void* ma_bridge_node_peaking_eq_init(void);
MA_BRIDGE_EXPORT void ma_bridge_node_peaking_eq_set_params(void* node_handle, float gainDB, float q, float frequency);

// Low Shelf Node (Bass)
MA_BRIDGE_EXPORT void* ma_bridge_node_low_shelf_init(void);
MA_BRIDGE_EXPORT void ma_bridge_node_low_shelf_set_params(void* node_handle, float gainDB, float q, float frequency);

// High Shelf Node (Treble)
MA_BRIDGE_EXPORT void* ma_bridge_node_high_shelf_init(void);
MA_BRIDGE_EXPORT void ma_bridge_node_high_shelf_set_params(void* node_handle, float gainDB, float q, float frequency);

// Splitter Node
MA_BRIDGE_EXPORT void* ma_bridge_node_splitter_init(void);
MA_BRIDGE_EXPORT void ma_bridge_node_splitter_set_volume(void* node_handle, int outputIndex, float volume);

// Node Graph Wiring
MA_BRIDGE_EXPORT void ma_bridge_node_attach_output_bus(void* node_handle, int outputBusIndex, void* dest_node_handle, int destInputBusIndex);
MA_BRIDGE_EXPORT void ma_bridge_node_detach_output_bus(void* node_handle, int outputBusIndex);
MA_BRIDGE_EXPORT void* ma_bridge_engine_get_endpoint(void); // Uses the global engine

// Node Management
MA_BRIDGE_EXPORT void ma_bridge_node_uninit(void* node_handle);

// Routing
/**
 * Route a Sound to a specific Node (instead of the Engine's master output).
 * @param sound_handle The sound to reroute.
 * @param node_handle The effect node to connect to. If NULL, connects to Engine Output.
 */
MA_BRIDGE_EXPORT void ma_bridge_sound_route_to_node(void* sound_handle, void* node_handle);

MA_BRIDGE_EXPORT void ma_bridge_deinit(void);

#ifdef __cplusplus
}
#endif

#endif /* MINIAUDIO_BRIDGE_H */
