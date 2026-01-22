/*
 * miniaudio_bridge.c - FFI Bridge Implementation
 * 
 * Core implementation of the miniaudio bridge for Flutter.
 * Provides:
 * 1. Device Context API (Enumeration)
 * 2. Low-level Device API (Pull-mode Stream)
 * 3. High-level Engine API (Mixing, Sounds)
 */

#define MINIAUDIO_IMPLEMENTATION
#include "miniaudio.h"
#include "miniaudio_bridge.h"

#include <string.h>
#include <stdio.h>
#include <stdlib.h>

/* --- Globals --- */

/* Context (Device Enumeration & Management) */
static ma_context g_context;
static int g_context_initialized = 0;

/* Device (Low-Level Stream) */
static ma_device g_device;
static int g_device_initialized = 0;
static int g_device_started = 0;

/* Engine (High-Level Mixer) */
static ma_engine g_engine;
static int g_engine_initialized = 0;

/* Device FIFO state (legacy/stream mode) */
static int16_t* g_fifo = NULL;
static int g_fifo_capacity = 0;
static volatile int* g_read_pos = NULL;
static volatile int* g_write_pos = NULL;
static int g_channels = 2; /* Synced with device config */
static uint64_t g_frames_consumed = 0;


/* --- Internal Helpers --- */

static ma_result EnsureContextInit(void) {
    if (g_context_initialized) return MA_SUCCESS;
    
    ma_result result = ma_context_init(NULL, 0, NULL, &g_context);
    if (result == MA_SUCCESS) {
        g_context_initialized = 1;
        printf("[miniaudio_bridge] Context initialized\n");
    } else {
        printf("[miniaudio_bridge] Failed to init context: %d\n", result);
    }
    return result;
}

/* --- Context / Enumeration API --- */

MA_BRIDGE_EXPORT int32_t ma_bridge_context_get_device_count(int32_t type) {
    if (EnsureContextInit() != MA_SUCCESS) return 0;
    
    ma_device_info* pPlaybackInfos;
    ma_uint32 playbackCount;
    ma_device_info* pCaptureInfos;
    ma_uint32 captureCount;
    
    if (ma_context_get_devices(&g_context, &pPlaybackInfos, &playbackCount, &pCaptureInfos, &captureCount) != MA_SUCCESS) {
        return 0;
    }
    
    return (type == 0) ? (int32_t)playbackCount : (int32_t)captureCount;
}

MA_BRIDGE_EXPORT int32_t ma_bridge_context_get_device_info(int32_t type, int32_t index, char* name_buffer, int32_t name_len, void* id_buffer, int32_t id_len) {
    if (EnsureContextInit() != MA_SUCCESS) return -1;
    
    ma_device_info* pPlaybackInfos;
    ma_uint32 playbackCount;
    ma_device_info* pCaptureInfos;
    ma_uint32 captureCount;
    
    if (ma_context_get_devices(&g_context, &pPlaybackInfos, &playbackCount, &pCaptureInfos, &captureCount) != MA_SUCCESS) {
        return -1;
    }
    
    ma_device_info* pInfo = NULL;
    if (type == 0) { // Playback
        if (index >= 0 && index < (int32_t)playbackCount) pInfo = &pPlaybackInfos[index];
    } else { // Capture
        if (index >= 0 && index < (int32_t)captureCount) pInfo = &pCaptureInfos[index];
    }
    
    if (pInfo) {
        /* Copy Name */
        if (name_buffer && name_len > 0) {
            strncpy(name_buffer, pInfo->name, name_len - 1);
            name_buffer[name_len - 1] = '\0';
        }
        
        /* Copy ID */
        if (id_buffer && id_len >= sizeof(ma_device_id)) {
            memcpy(id_buffer, &pInfo->id, sizeof(ma_device_id));
        }
        return 0;
    }
    
    return -1;
}


/* --- Device API (Low Level Stream) --- */

static void data_callback(ma_device* pDevice, void* pOutput, const void* pInput, ma_uint32 frameCount) {
    (void)pInput;
    (void)pDevice;
    
    int16_t* output = (int16_t*)pOutput;
    int samples_needed = frameCount * g_channels;
    
    if (g_fifo == NULL || g_read_pos == NULL || g_write_pos == NULL) {
        memset(output, 0, samples_needed * sizeof(int16_t));
        return;
    }
    
    int read = *g_read_pos;
    int write = *g_write_pos;
    
    int available;
    if (write >= read) {
        available = write - read;
    } else {
        available = g_fifo_capacity - read + write;
    }
    
    int samples_to_read = (available < samples_needed) ? available : samples_needed;
    int frames_to_read = samples_to_read / g_channels;
    
    for (int i = 0; i < samples_to_read; i++) {
        output[i] = g_fifo[(read + i) % g_fifo_capacity];
    }
    
    if (samples_to_read < samples_needed) {
        memset(output + samples_to_read, 0, (samples_needed - samples_to_read) * sizeof(int16_t));
    }
    
    *g_read_pos = (read + samples_to_read) % g_fifo_capacity;
    g_frames_consumed += frames_to_read;
}

MA_BRIDGE_EXPORT int ma_bridge_init_with_device_id(void* device_id, int sample_rate, int channels, int buffer_frames) {
    if (g_device_initialized) ma_bridge_deinit(); // Deinit device only
    EnsureContextInit(); // Context is reused
    
    g_channels = channels;
    g_frames_consumed = 0;
    
    ma_device_config config = ma_device_config_init(ma_device_type_playback);
    config.playback.format = ma_format_s16;
    config.playback.channels = channels;
    config.playback.pDeviceID = (ma_device_id*)device_id; // Can be NULL
    config.sampleRate = sample_rate;
    config.dataCallback = data_callback;
    config.periodSizeInFrames = buffer_frames;
    config.performanceProfile = ma_performance_profile_low_latency;
    
    if (ma_device_init(&g_context, &config, &g_device) != MA_SUCCESS) {
        printf("[miniaudio_bridge] Failed to init device\n");
        return -1;
    }
    
    g_device_initialized = 1;
    return 0;
}

MA_BRIDGE_EXPORT int ma_bridge_init(int sample_rate, int channels, int buffer_frames) {
    return ma_bridge_init_with_device_id(NULL, sample_rate, channels, buffer_frames);
}

MA_BRIDGE_EXPORT void ma_bridge_set_fifo(int16_t* fifo_ptr, int capacity_samples, volatile int* read_pos, volatile int* write_pos) {
    g_fifo = fifo_ptr;
    g_fifo_capacity = capacity_samples;
    g_read_pos = read_pos;
    g_write_pos = write_pos;
    if (read_pos) *read_pos = 0;
    if (write_pos) *write_pos = 0;
}

MA_BRIDGE_EXPORT int ma_bridge_start(void) {
    if (!g_device_initialized) return -1;
    if (g_device_started) return 0;
    
    if (ma_device_start(&g_device) != MA_SUCCESS) return -1;
    g_device_started = 1;
    return 0;
}

MA_BRIDGE_EXPORT int ma_bridge_stop(void) {
    if (!g_device_initialized || !g_device_started) return 0;
    if (ma_device_stop(&g_device) != MA_SUCCESS) return -1;
    g_device_started = 0;
    return 0;
}

MA_BRIDGE_EXPORT uint64_t ma_bridge_get_frames_consumed(void) {
    return g_frames_consumed;
}

MA_BRIDGE_EXPORT int32_t ma_bridge_get_fifo_available(void) {
    if (!g_read_pos || !g_write_pos) return 0;
    int r = *g_read_pos;
    int w = *g_write_pos;
    return (w >= r) ? (w - r) : (g_fifo_capacity - r + w);
}

MA_BRIDGE_EXPORT void ma_bridge_set_volume(float volume) {
    if (g_device_initialized) ma_device_set_master_volume(&g_device, volume);
}

MA_BRIDGE_EXPORT int32_t ma_bridge_get_device_sample_rate(void) {
    return g_device_initialized ? g_device.sampleRate : 0;
}

MA_BRIDGE_EXPORT int32_t ma_bridge_get_device_channels(void) {
    return g_device_initialized ? g_device.playback.channels : 0;
}

/* --- Engine API (High Level) --- */

MA_BRIDGE_EXPORT int ma_bridge_engine_init(void) {
    if (g_engine_initialized) return 0;
    
    // Engine uses its own internal context/device management usually, 
    // unless we pass a config. For simplicity, let engine manage itself.
    ma_engine_config config = ma_engine_config_init();
    
    if (ma_engine_init(&config, &g_engine) != MA_SUCCESS) {
        printf("[miniaudio_bridge] Failed to init engine\n");
        return -1;
    }
    g_engine_initialized = 1;
    return 0;
}

MA_BRIDGE_EXPORT void ma_bridge_engine_uninit(void) {
    if (g_engine_initialized) {
        ma_engine_uninit(&g_engine);
        g_engine_initialized = 0;
    }
}

MA_BRIDGE_EXPORT int ma_bridge_engine_start(void) {
    if (!g_engine_initialized) return -1;
    return ma_engine_start(&g_engine) == MA_SUCCESS ? 0 : -1;
}

MA_BRIDGE_EXPORT int ma_bridge_engine_stop(void) {
    if (!g_engine_initialized) return -1;
    return ma_engine_stop(&g_engine) == MA_SUCCESS ? 0 : -1;
}

MA_BRIDGE_EXPORT void ma_bridge_engine_set_volume(float volume) {
    if (g_engine_initialized) ma_engine_set_volume(&g_engine, volume);
}

MA_BRIDGE_EXPORT void ma_bridge_engine_play_sound(const char* path) {
    if (g_engine_initialized) ma_engine_play_sound(&g_engine, path, NULL);
}

/* --- Listener API --- */

MA_BRIDGE_EXPORT void ma_bridge_engine_listener_set_position(int32_t listenerIndex, float x, float y, float z) {
    if (g_engine_initialized) ma_engine_listener_set_position(&g_engine, (ma_uint32)listenerIndex, x, y, z);
}

MA_BRIDGE_EXPORT void ma_bridge_engine_listener_set_direction(int32_t listenerIndex, float x, float y, float z) {
    if (g_engine_initialized) ma_engine_listener_set_direction(&g_engine, (ma_uint32)listenerIndex, x, y, z);
}

MA_BRIDGE_EXPORT void ma_bridge_engine_listener_set_velocity(int32_t listenerIndex, float x, float y, float z) {
    if (g_engine_initialized) ma_engine_listener_set_velocity(&g_engine, (ma_uint32)listenerIndex, x, y, z);
}

MA_BRIDGE_EXPORT void ma_bridge_engine_listener_set_world_up(int32_t listenerIndex, float x, float y, float z) {
    if (g_engine_initialized) ma_engine_listener_set_world_up(&g_engine, (ma_uint32)listenerIndex, x, y, z);
}

MA_BRIDGE_EXPORT void ma_bridge_engine_listener_set_cone(int32_t listenerIndex, float innerAngle, float outerAngle, float outerGain) {
    if (g_engine_initialized) ma_engine_listener_set_cone(&g_engine, (ma_uint32)listenerIndex, innerAngle, outerAngle, outerGain);
}

MA_BRIDGE_EXPORT void ma_bridge_engine_listener_set_enabled(int32_t listenerIndex, int32_t enabled) {
    if (g_engine_initialized) ma_engine_listener_set_enabled(&g_engine, (ma_uint32)listenerIndex, enabled ? MA_TRUE : MA_FALSE);
}

/* --- Sound API --- */

MA_BRIDGE_EXPORT void* ma_bridge_sound_init_from_file(const char* path, int32_t flags) {
    if (!g_engine_initialized) return NULL;
    
    ma_sound* sound = (ma_sound*)malloc(sizeof(ma_sound));
    if (!sound) return NULL;
    
    // Default flags if 0. MA_SOUND_FLAG_DECODE is often good for small SFX.
    // MA_SOUND_FLAG_STREAM is good for BGM.
    // We let user pass flags (or use default). 
    // Usually one wants explicit flags, but let's handle simple case.
    ma_uint32 ma_flags = (ma_uint32)flags; 
    
    if (ma_sound_init_from_file(&g_engine, path, ma_flags, NULL, NULL, sound) != MA_SUCCESS) {
        free(sound);
        return NULL;
    }
    return sound;
}

MA_BRIDGE_EXPORT void* ma_bridge_sound_init_from_file_with_group(const char* path, void* group_handle, int32_t flags) {
    if (!g_engine_initialized) return NULL;
    
    ma_sound* sound = (ma_sound*)malloc(sizeof(ma_sound));
    if (!sound) return NULL;
    
    ma_uint32 ma_flags = (ma_uint32)flags; 
    
    // Pass group_handle as the 4th argument (pGroup)
    if (ma_sound_init_from_file(&g_engine, path, ma_flags, (ma_sound_group*)group_handle, NULL, sound) != MA_SUCCESS) {
        free(sound);
        return NULL;
    }
    return sound;
}

MA_BRIDGE_EXPORT void ma_bridge_sound_uninit(void* sound_handle) {
    if (sound_handle) {
        ma_sound_uninit((ma_sound*)sound_handle);
        free(sound_handle);
    }
}

MA_BRIDGE_EXPORT void ma_bridge_sound_play(void* sound_handle) {
    if (sound_handle) ma_sound_start((ma_sound*)sound_handle);
}

MA_BRIDGE_EXPORT void ma_bridge_sound_stop(void* sound_handle) {
    if (sound_handle) ma_sound_stop((ma_sound*)sound_handle);
}

MA_BRIDGE_EXPORT void ma_bridge_sound_set_volume(void* sound_handle, float volume) {
    if (sound_handle) ma_sound_set_volume((ma_sound*)sound_handle, volume);
}

MA_BRIDGE_EXPORT void ma_bridge_sound_set_pitch(void* sound_handle, float pitch) {
    if (sound_handle) ma_sound_set_pitch((ma_sound*)sound_handle, pitch);
}

MA_BRIDGE_EXPORT void ma_bridge_sound_set_pan(void* sound_handle, float pan) {
    if (sound_handle) ma_sound_set_pan((ma_sound*)sound_handle, pan);
}

MA_BRIDGE_EXPORT void ma_bridge_sound_set_looping(void* sound_handle, int32_t loop) {
    if (sound_handle) ma_sound_set_looping((ma_sound*)sound_handle, loop ? MA_TRUE : MA_FALSE);
}

MA_BRIDGE_EXPORT void ma_bridge_sound_set_position(void* sound_handle, float x, float y, float z) {
    if (sound_handle) ma_sound_set_position((ma_sound*)sound_handle, x, y, z);
}

MA_BRIDGE_EXPORT void ma_bridge_sound_set_direction(void* sound_handle, float x, float y, float z) {
    if (sound_handle) ma_sound_set_direction((ma_sound*)sound_handle, x, y, z);
}

MA_BRIDGE_EXPORT void ma_bridge_sound_set_velocity(void* sound_handle, float x, float y, float z) {
    if (sound_handle) ma_sound_set_velocity((ma_sound*)sound_handle, x, y, z);
}

MA_BRIDGE_EXPORT void ma_bridge_sound_set_cone(void* sound_handle, float innerAngle, float outerAngle, float outerGain) {
    if (sound_handle) ma_sound_set_cone((ma_sound*)sound_handle, innerAngle, outerAngle, outerGain);
}

MA_BRIDGE_EXPORT void ma_bridge_sound_set_doppler_factor(void* sound_handle, float factor) {
    if (sound_handle) ma_sound_set_doppler_factor((ma_sound*)sound_handle, factor);
}

MA_BRIDGE_EXPORT void ma_bridge_sound_set_fade_in_pcm_frames(void* sound_handle, float volumeBeg, float volumeEnd, uint64_t len) {
    if (sound_handle) ma_sound_set_fade_in_pcm_frames((ma_sound*)sound_handle, volumeBeg, volumeEnd, len);
}

MA_BRIDGE_EXPORT void ma_bridge_sound_set_fade_start_time(void* sound_handle, uint64_t absoluteGlobalTime) {
    if (sound_handle) ma_sound_set_fade_start_time((ma_sound*)sound_handle, absoluteGlobalTime);
}

MA_BRIDGE_EXPORT void ma_bridge_sound_seek_to_pcm_frame(void* sound_handle, uint64_t frameIndex) {
    if (sound_handle) ma_sound_seek_to_pcm_frame((ma_sound*)sound_handle, frameIndex);
}

MA_BRIDGE_EXPORT uint64_t ma_bridge_sound_get_length_in_pcm_frames(void* sound_handle) {
    if (!sound_handle) return 0;
    ma_uint64 length;
    if (ma_sound_get_length_in_pcm_frames((ma_sound*)sound_handle, &length) != MA_SUCCESS) return 0;
    return length;
}

MA_BRIDGE_EXPORT uint64_t ma_bridge_sound_get_cursor_in_pcm_frames(void* sound_handle) {
    if (!sound_handle) return 0;
    ma_uint64 cursor;
    if (ma_sound_get_cursor_in_pcm_frames((ma_sound*)sound_handle, &cursor) != MA_SUCCESS) return 0;
    return cursor;
}

MA_BRIDGE_EXPORT int32_t ma_bridge_sound_is_playing(void* sound_handle) {
    return sound_handle ? ma_sound_is_playing((ma_sound*)sound_handle) : 0;
}

MA_BRIDGE_EXPORT int32_t ma_bridge_sound_at_end(void* sound_handle) {
    return sound_handle ? ma_sound_at_end((ma_sound*)sound_handle) : 1;
}

/* --- Sound Group API --- */

MA_BRIDGE_EXPORT void* ma_bridge_sound_group_init(void* parent_group_handle) {
    if (!g_engine_initialized) return NULL;

    ma_sound_group* group = (ma_sound_group*)malloc(sizeof(ma_sound_group));
    if (!group) return NULL;

    // init_sends = NULL, NULL (no custom DSP graph yet)
    // parent group can be NULL (defaults to engine master)
    if (ma_sound_group_init(&g_engine, 0, (ma_sound_group*)parent_group_handle, group) != MA_SUCCESS) {
        free(group);
        return NULL;
    }
    return group;
}

MA_BRIDGE_EXPORT void ma_bridge_sound_group_uninit(void* group_handle) {
    if (group_handle) {
        ma_sound_group_uninit((ma_sound_group*)group_handle);
        free(group_handle);
    }
}

MA_BRIDGE_EXPORT void ma_bridge_sound_group_start(void* group_handle) {
    if (group_handle) ma_sound_group_start((ma_sound_group*)group_handle);
}

MA_BRIDGE_EXPORT void ma_bridge_sound_group_stop(void* group_handle) {
    if (group_handle) ma_sound_group_stop((ma_sound_group*)group_handle);
}

MA_BRIDGE_EXPORT void ma_bridge_sound_group_set_volume(void* group_handle, float volume) {
    if (group_handle) ma_sound_group_set_volume((ma_sound_group*)group_handle, volume);
}

MA_BRIDGE_EXPORT void ma_bridge_sound_group_set_pan(void* group_handle, float pan) {
    if (group_handle) ma_sound_group_set_pan((ma_sound_group*)group_handle, pan);
}

MA_BRIDGE_EXPORT void ma_bridge_sound_group_set_pitch(void* group_handle, float pitch) {
    if (group_handle) ma_sound_group_set_pitch((ma_sound_group*)group_handle, pitch);
}


/* --- Advanced Node API (EQ / Filter / Splitter) --- */

// --- Base Node Helpers ---
// (We might add more helper functions here later if needed)

// --- HPF --- (Implemented in previous step, checking existence)
MA_BRIDGE_EXPORT void* ma_bridge_node_hpf_init(void) {
    if (!g_engine_initialized) return NULL;
    ma_hpf_node* node = (ma_hpf_node*)malloc(sizeof(ma_hpf_node));
    if (!node) return NULL;

    ma_hpf_node_config config = ma_hpf_node_config_init(g_engine.pResourceManager->config.channels, g_engine.sampleRate, 0); // 0 cutoff initially
    if (ma_hpf_node_init(ma_engine_get_node_graph(&g_engine), &config, NULL, node) != MA_SUCCESS) {
        free(node);
        return NULL;
    }
    return node;
}

MA_BRIDGE_EXPORT void ma_bridge_node_hpf_set_cutoff(void* node_handle, float cutoffFrequency) {
    if (node_handle) ma_hpf_node_set_cutoff_frequency((ma_hpf_node*)node_handle, cutoffFrequency);
}

// --- Peaking EQ ---

MA_BRIDGE_EXPORT void* ma_bridge_node_peaking_eq_init(void) {
    if (!g_engine_initialized) return NULL;
    ma_peak_node* node = (ma_peak_node*)malloc(sizeof(ma_peak_node));
    if (!node) return NULL;

    // channels, sampleRate, gainDB, q, freq
    ma_peak_node_config config = ma_peak_node_config_init(g_engine.pResourceManager->config.channels, g_engine.sampleRate, 0, 1, 1000); 
    if (ma_peak_node_init(ma_engine_get_node_graph(&g_engine), &config, NULL, node) != MA_SUCCESS) {
        free(node);
        return NULL;
    }
    return node;
}

MA_BRIDGE_EXPORT void ma_bridge_node_peaking_eq_set_params(void* node_handle, float gainDB, float q, float frequency) {
    if (node_handle) {
        ma_peak_node_set_gain_db((ma_peak_node*)node_handle, gainDB);
        ma_peak_node_set_q((ma_peak_node*)node_handle, q);
        ma_peak_node_set_frequency((ma_peak_node*)node_handle, frequency);
    }
}

// --- Low Shelf ---

MA_BRIDGE_EXPORT void* ma_bridge_node_low_shelf_init(void) {
    if (!g_engine_initialized) return NULL;
    ma_loshelf_node* node = (ma_loshelf_node*)malloc(sizeof(ma_loshelf_node));
    if (!node) return NULL;

    ma_loshelf_node_config config = ma_loshelf_node_config_init(g_engine.pResourceManager->config.channels, g_engine.sampleRate, 0, 1, 200);
    if (ma_loshelf_node_init(ma_engine_get_node_graph(&g_engine), &config, NULL, node) != MA_SUCCESS) {
        free(node);
        return NULL;
    }
    return node;
}

MA_BRIDGE_EXPORT void ma_bridge_node_low_shelf_set_params(void* node_handle, float gainDB, float q, float frequency) {
    if (node_handle) {
        ma_loshelf_node_set_gain_db((ma_loshelf_node*)node_handle, gainDB);
        ma_loshelf_node_set_q((ma_loshelf_node*)node_handle, q);
        ma_loshelf_node_set_frequency((ma_loshelf_node*)node_handle, frequency);
    }
}

// --- High Shelf ---

MA_BRIDGE_EXPORT void* ma_bridge_node_high_shelf_init(void) {
    if (!g_engine_initialized) return NULL;
    ma_hishelf_node* node = (ma_hishelf_node*)malloc(sizeof(ma_hishelf_node));
    if (!node) return NULL;

    ma_hishelf_node_config config = ma_hishelf_node_config_init(g_engine.pResourceManager->config.channels, g_engine.sampleRate, 0, 1, 4000);
    if (ma_hishelf_node_init(ma_engine_get_node_graph(&g_engine), &config, NULL, node) != MA_SUCCESS) {
        free(node);
        return NULL;
    }
    return node;
}

MA_BRIDGE_EXPORT void ma_bridge_node_high_shelf_set_params(void* node_handle, float gainDB, float q, float frequency) {
    if (node_handle) {
        ma_hishelf_node_set_gain_db((ma_hishelf_node*)node_handle, gainDB);
        ma_hishelf_node_set_q((ma_hishelf_node*)node_handle, q);
        ma_hishelf_node_set_frequency((ma_hishelf_node*)node_handle, frequency);
    }
}

// --- Splitter ---

MA_BRIDGE_EXPORT void* ma_bridge_node_splitter_init(void) {
    if (!g_engine_initialized) return NULL;
    ma_splitter_node* node = (ma_splitter_node*)malloc(sizeof(ma_splitter_node));
    if (!node) return NULL;

    // Default: 2 outputs
    ma_splitter_node_config config = ma_splitter_node_config_init(g_engine.pResourceManager->config.channels);
    if (ma_splitter_node_init(ma_engine_get_node_graph(&g_engine), &config, NULL, node) != MA_SUCCESS) {
        free(node);
        return NULL;
    }
    return node;
}

MA_BRIDGE_EXPORT void ma_bridge_node_splitter_set_volume(void* node_handle, int outputIndex, float volume) {
    if (node_handle) {
         ma_splitter_node_set_output_bus_volume((ma_splitter_node*)node_handle, (ma_uint32)outputIndex, volume);
    }
}

// --- Node Graph Wiring ---
MA_BRIDGE_EXPORT void ma_bridge_node_attach_output_bus(void* node_handle, int outputBusIndex, void* dest_node_handle, int destInputBusIndex) {
    if (node_handle && dest_node_handle) {
        ma_node_attach_output_bus((ma_node*)node_handle, (ma_uint32)outputBusIndex, (ma_node*)dest_node_handle, (ma_uint32)destInputBusIndex);
    }
}

MA_BRIDGE_EXPORT void ma_bridge_node_detach_output_bus(void* node_handle, int outputBusIndex) {
    if (node_handle) {
        ma_node_detach_output_bus((ma_node*)node_handle, (ma_uint32)outputBusIndex);
    }
}

MA_BRIDGE_EXPORT void* ma_bridge_engine_get_endpoint(void) {
    if (!g_device_initialized) return NULL;
    // The endpoint is a node. miniaudio engine uses a single endpoint.
    return (void*)ma_engine_get_endpoint(&g_engine);
}

MA_BRIDGE_EXPORT void ma_bridge_deinit(void) {
    ma_bridge_stop();
    if (g_device_initialized) {
        ma_device_uninit(&g_device);
        g_device_initialized = 0;
    }
    // Note: We don't necessarily uninit context or engine here as they might be shared or needed later?
    // But for "deinit all", maybe we should? 
    // Let's keep context/engine alive unless explicitly uninited, 
    // OR create a `ma_bridge_shutdown` for full cleanup.
    // For now, `ma_bridge_deinit` was originally for the Device.
}
