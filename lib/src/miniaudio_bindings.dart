/// FFI bindings for miniaudio_bridge native library.
library;

import 'dart:ffi';
import 'package:ffi/ffi.dart';

// --- Context / Enumeration Types ---
typedef MaBridgeContextGetDeviceCountNative = Int32 Function(Int32 type);
typedef MaBridgeContextGetDeviceCountDart = int Function(int type);

typedef MaBridgeContextGetDeviceInfoNative = Int32 Function(
    Int32 type,
    Int32 index,
    Pointer<Utf8> nameBuffer,
    Int32 nameLen,
    Pointer<Void> idBuffer,
    Int32 idLen);
typedef MaBridgeContextGetDeviceInfoDart = int Function(int type, int index,
    Pointer<Utf8> nameBuffer, int nameLen, Pointer<Void> idBuffer, int idLen);

// --- Device Types ---
typedef MaBridgeInitNative = Int32 Function(Pointer<Void> deviceId,
    Int32 sampleRate, Int32 channels, Int32 bufferFrames);
typedef MaBridgeInitDart = int Function(
    Pointer<Void> deviceId, int sampleRate, int channels, int bufferFrames);

typedef MaBridgeSetFifoNative = Void Function(
  Pointer<Int16> fifoPtr,
  Int32 capacitySamples,
  Pointer<Int32> readPos,
  Pointer<Int32> writePos,
);
typedef MaBridgeSetFifoDart = void Function(
  Pointer<Int16> fifoPtr,
  int capacitySamples,
  Pointer<Int32> readPos,
  Pointer<Int32> writePos,
);

typedef MaBridgeStartNative = Int32 Function();
typedef MaBridgeStartDart = int Function();

typedef MaBridgeStopNative = Int32 Function();
typedef MaBridgeStopDart = int Function();

typedef MaBridgeGetFramesConsumedNative = Uint64 Function();
typedef MaBridgeGetFramesConsumedDart = int Function();

typedef MaBridgeGetFifoAvailableNative = Int32 Function();
typedef MaBridgeGetFifoAvailableDart = int Function();

typedef MaBridgeSetVolumeNative = Void Function(Float volume);
typedef MaBridgeSetVolumeDart = void Function(double volume);

typedef MaBridgeGetDeviceSampleRateNative = Int32 Function();
typedef MaBridgeGetDeviceSampleRateDart = int Function();

typedef MaBridgeGetDeviceChannelsNative = Int32 Function();
typedef MaBridgeGetDeviceChannelsDart = int Function();

// --- Engine Types ---
typedef MaBridgeEngineInitNative = Int32 Function();
typedef MaBridgeEngineInitDart = int Function();

typedef MaBridgeEngineUninitNative = Void Function();
typedef MaBridgeEngineUninitDart = void Function();

typedef MaBridgeEngineStartNative = Int32 Function();
typedef MaBridgeEngineStartDart = int Function();

typedef MaBridgeEngineStopNative = Int32 Function();
typedef MaBridgeEngineStopDart = int Function();

typedef MaBridgeEngineSetVolumeNative = Void Function(Float volume);
typedef MaBridgeEngineSetVolumeDart = void Function(double volume);

typedef MaBridgeEnginePlaySoundNative = Void Function(Pointer<Utf8> path);
typedef MaBridgeEnginePlaySoundDart = void Function(Pointer<Utf8> path);

typedef MaBridgeEngineGetEndpointNative = Pointer<Void> Function();
typedef MaBridgeEngineGetEndpointDart = Pointer<Void> Function();

// --- Sound Types ---
typedef MaBridgeSoundInitFromFileNative = Pointer<Void> Function(
    Pointer<Utf8> path, Int32 flags);
typedef MaBridgeSoundInitFromFileDart = Pointer<Void> Function(
    Pointer<Utf8> path, int flags);

typedef MaBridgeSoundInitFromMemoryNative = Pointer<Void> Function(
    Pointer<Void> data, Size size, Int32 flags);
typedef MaBridgeSoundInitFromMemoryDart = Pointer<Void> Function(
    Pointer<Void> data, int size, int flags);

typedef MaBridgeSoundInitNoiseNative = Pointer<Void> Function(
    Int32 type, Float amplitude, Int32 seed);
typedef MaBridgeSoundInitNoiseDart = Pointer<Void> Function(
    int type, double amplitude, int seed);

typedef MaBridgeSoundInitWaveformNative = Pointer<Void> Function(
    Int32 type, Float amplitude, Double frequency);
typedef MaBridgeSoundInitWaveformDart = Pointer<Void> Function(
    int type, double amplitude, double frequency);

typedef MaBridgeSoundUninitNative = Void Function(Pointer<Void> soundHandle);
typedef MaBridgeSoundUninitDart = void Function(Pointer<Void> soundHandle);

typedef MaBridgeSoundPlayNative = Void Function(Pointer<Void> soundHandle);
typedef MaBridgeSoundPlayDart = void Function(Pointer<Void> soundHandle);

typedef MaBridgeSoundStopNative = Void Function(Pointer<Void> soundHandle);
typedef MaBridgeSoundStopDart = void Function(Pointer<Void> soundHandle);

typedef MaBridgeSoundSetVolumeNative = Void Function(
    Pointer<Void> soundHandle, Float volume);
typedef MaBridgeSoundSetVolumeDart = void Function(
    Pointer<Void> soundHandle, double volume);

typedef MaBridgeSoundSetPitchNative = Void Function(
    Pointer<Void> soundHandle, Float pitch);
typedef MaBridgeSoundSetPitchDart = void Function(
    Pointer<Void> soundHandle, double pitch);

typedef MaBridgeSoundSetPanNative = Void Function(
    Pointer<Void> soundHandle, Float pan);
typedef MaBridgeSoundSetPanDart = void Function(
    Pointer<Void> soundHandle, double pan);

typedef MaBridgeSoundSetLoopingNative = Void Function(
    Pointer<Void> soundHandle, Int32 loop);
typedef MaBridgeSoundSetLoopingDart = void Function(
    Pointer<Void> soundHandle, int loop);

typedef MaBridgeSoundSetPositionNative = Void Function(
    Pointer<Void> soundHandle, Float x, Float y, Float z);
typedef MaBridgeSoundSetPositionDart = void Function(
    Pointer<Void> soundHandle, double x, double y, double z);

typedef MaBridgeSoundSetDirectionNative = Void Function(
    Pointer<Void> soundHandle, Float x, Float y, Float z);
typedef MaBridgeSoundSetDirectionDart = void Function(
    Pointer<Void> soundHandle, double x, double y, double z);

typedef MaBridgeSoundSetVelocityNative = Void Function(
    Pointer<Void> soundHandle, Float x, Float y, Float z);
typedef MaBridgeSoundSetVelocityDart = void Function(
    Pointer<Void> soundHandle, double x, double y, double z);

typedef MaBridgeSoundSetConeNative = Void Function(Pointer<Void> soundHandle,
    Float innerAngle, Float outerAngle, Float outerGain);
typedef MaBridgeSoundSetConeDart = void Function(Pointer<Void> soundHandle,
    double innerAngle, double outerAngle, double outerGain);

typedef MaBridgeSoundSetDopplerFactorNative = Void Function(
    Pointer<Void> soundHandle, Float factor);
typedef MaBridgeSoundSetDopplerFactorDart = void Function(
    Pointer<Void> soundHandle, double factor);

typedef MaBridgeSoundSetFadeInPcmFramesNative = Void Function(
    Pointer<Void> soundHandle, Float volumeBeg, Float volumeEnd, Uint64 len);
typedef MaBridgeSoundSetFadeInPcmFramesDart = void Function(
    Pointer<Void> soundHandle, double volumeBeg, double volumeEnd, int len);

typedef MaBridgeSoundSetFadeStartTimeNative = Void Function(
    Pointer<Void> soundHandle,
    Float volumeBeg,
    Float volumeEnd,
    Uint64 len,
    Uint64 absoluteGlobalTime);
typedef MaBridgeSoundSetFadeStartTimeDart = void Function(
    Pointer<Void> soundHandle,
    double volumeBeg,
    double volumeEnd,
    int len,
    int absoluteGlobalTime);

typedef MaBridgeSoundSeekToPcmFrameNative = Void Function(
    Pointer<Void> soundHandle, Uint64 frameIndex);
typedef MaBridgeSoundSeekToPcmFrameDart = void Function(
    Pointer<Void> soundHandle, int frameIndex);

typedef MaBridgeSoundGetLengthInPcmFramesNative = Uint64 Function(
    Pointer<Void> soundHandle);
typedef MaBridgeSoundGetLengthInPcmFramesDart = int Function(
    Pointer<Void> soundHandle);

typedef MaBridgeSoundGetCursorInPcmFramesNative = Uint64 Function(
    Pointer<Void> soundHandle);
typedef MaBridgeSoundGetCursorInPcmFramesDart = int Function(
    Pointer<Void> soundHandle);

typedef MaBridgeSoundIsPlayingNative = Int32 Function(
    Pointer<Void> soundHandle);
typedef MaBridgeSoundIsPlayingDart = int Function(Pointer<Void> soundHandle);

typedef MaBridgeSoundAtEndNative = Int32 Function(Pointer<Void> soundHandle);
typedef MaBridgeSoundAtEndDart = int Function(Pointer<Void> soundHandle);

typedef MaBridgeDeinitNative = Void Function();
typedef MaBridgeDeinitDart = void Function();

// --- Listener Types ---
typedef MaBridgeEngineListenerSetPositionNative = Void Function(
    Int32 listenerIndex, Float x, Float y, Float z);
typedef MaBridgeEngineListenerSetPositionDart = void Function(
    int listenerIndex, double x, double y, double z);

typedef MaBridgeEngineListenerSetDirectionNative = Void Function(
    Int32 listenerIndex, Float x, Float y, Float z);
typedef MaBridgeEngineListenerSetDirectionDart = void Function(
    int listenerIndex, double x, double y, double z);

typedef MaBridgeEngineListenerSetVelocityNative = Void Function(
    Int32 listenerIndex, Float x, Float y, Float z);
typedef MaBridgeEngineListenerSetVelocityDart = void Function(
    int listenerIndex, double x, double y, double z);

typedef MaBridgeEngineListenerSetWorldUpNative = Void Function(
    Int32 listenerIndex, Float x, Float y, Float z);
typedef MaBridgeEngineListenerSetWorldUpDart = void Function(
    int listenerIndex, double x, double y, double z);

typedef MaBridgeEngineListenerSetConeNative = Void Function(
    Int32 listenerIndex, Float innerAngle, Float outerAngle, Float outerGain);
typedef MaBridgeEngineListenerSetConeDart = void Function(
    int listenerIndex, double innerAngle, double outerAngle, double outerGain);

typedef MaBridgeEngineListenerSetEnabledNative = Void Function(
    Int32 listenerIndex, Int32 enabled);
typedef MaBridgeEngineListenerSetEnabledDart = void Function(
    int listenerIndex, int enabled);

// --- Sound Group Types ---
typedef MaBridgeSoundGroupInitNative = Pointer<Void> Function(
    Pointer<Void> parentGroup);
typedef MaBridgeSoundGroupInitDart = Pointer<Void> Function(
    Pointer<Void> parentGroup);

typedef MaBridgeSoundGroupUninitNative = Void Function(
    Pointer<Void> groupHandle);
typedef MaBridgeSoundGroupUninitDart = void Function(Pointer<Void> groupHandle);

typedef MaBridgeSoundGroupStartNative = Void Function(
    Pointer<Void> groupHandle);
typedef MaBridgeSoundGroupStartDart = void Function(Pointer<Void> groupHandle);

typedef MaBridgeSoundGroupStopNative = Void Function(Pointer<Void> groupHandle);
typedef MaBridgeSoundGroupStopDart = void Function(Pointer<Void> groupHandle);

typedef MaBridgeSoundGroupSetVolumeNative = Void Function(
    Pointer<Void> groupHandle, Float volume);
typedef MaBridgeSoundGroupSetVolumeDart = void Function(
    Pointer<Void> groupHandle, double volume);

typedef MaBridgeSoundGroupSetPanNative = Void Function(
    Pointer<Void> groupHandle, Float pan);
typedef MaBridgeSoundGroupSetPanDart = void Function(
    Pointer<Void> groupHandle, double pan);

typedef MaBridgeSoundGroupSetPitchNative = Void Function(
    Pointer<Void> groupHandle, Float pitch);
typedef MaBridgeSoundGroupSetPitchDart = void Function(
    Pointer<Void> groupHandle, double pitch);

typedef MaBridgeSoundInitFromFileWithGroupNative = Pointer<Void> Function(
    Pointer<Utf8> path, Pointer<Void> groupHandle, Int32 flags);
typedef MaBridgeSoundInitFromFileWithGroupDart = Pointer<Void> Function(
    Pointer<Utf8> path, Pointer<Void> groupHandle, int flags);

typedef MaBridgeSoundRouteToNodeNative = Void Function(
    Pointer<Void> soundHandle, Pointer<Void> nodeHandle);
typedef MaBridgeSoundRouteToNodeDart = void Function(
    Pointer<Void> soundHandle, Pointer<Void> nodeHandle);

// --- Advanced Nodes (EQ / Filters) ---
typedef MaBridgeNodeUninitNative = Void Function(Pointer<Void> nodeHandle);
typedef MaBridgeNodeUninitDart = void Function(Pointer<Void> nodeHandle);

// HPF (Already defined usually, ensuring here if not)
typedef MaBridgeNodeHpfInitNative = Pointer<Void> Function();
typedef MaBridgeNodeHpfInitDart = Pointer<Void> Function();
typedef MaBridgeNodeHpfSetCutoffNative = Void Function(
    Pointer<Void> nodeHandle, Float cutoff);
typedef MaBridgeNodeHpfSetCutoffDart = void Function(
    Pointer<Void> nodeHandle, double cutoff);

// LPF
typedef MaBridgeNodeLpfInitNative = Pointer<Void> Function();
typedef MaBridgeNodeLpfInitDart = Pointer<Void> Function();
typedef MaBridgeNodeLpfSetCutoffNative = Void Function(
    Pointer<Void> nodeHandle, Float cutoff);
typedef MaBridgeNodeLpfSetCutoffDart = void Function(
    Pointer<Void> nodeHandle, double cutoff);

// BPF
typedef MaBridgeNodeBpfInitNative = Pointer<Void> Function();
typedef MaBridgeNodeBpfInitDart = Pointer<Void> Function();
typedef MaBridgeNodeBpfSetCutoffNative = Void Function(
    Pointer<Void> nodeHandle, Float cutoff);
typedef MaBridgeNodeBpfSetCutoffDart = void Function(
    Pointer<Void> nodeHandle, double cutoff);

// Delay
typedef MaBridgeNodeDelayInitNative = Pointer<Void> Function();
typedef MaBridgeNodeDelayInitDart = Pointer<Void> Function();
typedef MaBridgeNodeDelaySetDelayNative = Void Function(
    Pointer<Void> nodeHandle, Int32 delayMS);
typedef MaBridgeNodeDelaySetDelayDart = void Function(
    Pointer<Void> nodeHandle, int delayMS);
typedef MaBridgeNodeDelaySetWetNative = Void Function(
    Pointer<Void> nodeHandle, Float wet);
typedef MaBridgeNodeDelaySetWetDart = void Function(
    Pointer<Void> nodeHandle, double wet);
typedef MaBridgeNodeDelaySetDryNative = Void Function(
    Pointer<Void> nodeHandle, Float dry);
typedef MaBridgeNodeDelaySetDryDart = void Function(
    Pointer<Void> nodeHandle, double dry);
typedef MaBridgeNodeDelaySetDecayNative = Void Function(
    Pointer<Void> nodeHandle, Float decay);
typedef MaBridgeNodeDelaySetDecayDart = void Function(
    Pointer<Void> nodeHandle, double decay);

// Reverb
typedef MaBridgeNodeReverbInitNative = Pointer<Void> Function();
typedef MaBridgeNodeReverbInitDart = Pointer<Void> Function();
typedef MaBridgeNodeReverbSetParamsNative = Void Function(
    Pointer<Void> nodeHandle,
    Float roomSize,
    Float damping,
    Float width,
    Float wet,
    Float dry);
typedef MaBridgeNodeReverbSetParamsDart = void Function(
    Pointer<Void> nodeHandle,
    double roomSize,
    double damping,
    double width,
    double wet,
    double dry);

// Peaking EQ
typedef MaBridgeNodePeakingEqInitNative = Pointer<Void> Function();
typedef MaBridgeNodePeakingEqInitDart = Pointer<Void> Function();
typedef MaBridgeNodePeakingEqSetParamsNative = Void Function(
    Pointer<Void> nodeHandle, Float gainDB, Float q, Float frequency);
typedef MaBridgeNodePeakingEqSetParamsDart = void Function(
    Pointer<Void> nodeHandle, double gainDB, double q, double frequency);

// Low Shelf
typedef MaBridgeNodeLowShelfInitNative = Pointer<Void> Function();
typedef MaBridgeNodeLowShelfInitDart = Pointer<Void> Function();
typedef MaBridgeNodeLowShelfSetParamsNative = Void Function(
    Pointer<Void> nodeHandle, Float gainDB, Float q, Float frequency);
typedef MaBridgeNodeLowShelfSetParamsDart = void Function(
    Pointer<Void> nodeHandle, double gainDB, double q, double frequency);

// High Shelf
typedef MaBridgeNodeHighShelfInitNative = Pointer<Void> Function();
typedef MaBridgeNodeHighShelfInitDart = Pointer<Void> Function();
typedef MaBridgeNodeHighShelfSetParamsNative = Void Function(
    Pointer<Void> nodeHandle, Float gainDB, Float q, Float frequency);
typedef MaBridgeNodeHighShelfSetParamsDart = void Function(
    Pointer<Void> nodeHandle, double gainDB, double q, double frequency);

// Splitter
typedef MaBridgeNodeSplitterInitNative = Pointer<Void> Function();
typedef MaBridgeNodeSplitterInitDart = Pointer<Void> Function();
typedef MaBridgeNodeSplitterSetVolumeNative = Void Function(
    Pointer<Void> nodeHandle, Int32 outputIndex, Float volume);
typedef MaBridgeNodeSplitterSetVolumeDart = void Function(
    Pointer<Void> nodeHandle, int outputIndex, double volume);

// Wiring
typedef MaBridgeNodeAttachOutputBusNative = Void Function(
    Pointer<Void> nodeHandle,
    Int32 outputBusIndex,
    Pointer<Void> destNodeHandle,
    Int32 destInputBusIndex);
typedef MaBridgeNodeAttachOutputBusDart = void Function(
    Pointer<Void> nodeHandle,
    int outputBusIndex,
    Pointer<Void> destNodeHandle,
    int destInputBusIndex);

typedef MaBridgeNodeDetachOutputBusNative = Void Function(
    Pointer<Void> nodeHandle, Int32 outputBusIndex);
typedef MaBridgeNodeDetachOutputBusDart = void Function(
    Pointer<Void> nodeHandle, int outputBusIndex);

/// Bindings class for miniaudio bridge
class MiniaudioBindings {
  final DynamicLibrary _lib;

  // Context
  late final MaBridgeContextGetDeviceCountDart contextGetDeviceCount;
  late final MaBridgeContextGetDeviceInfoDart contextGetDeviceInfo;

  // Device
  late final MaBridgeInitDart init;
  late final MaBridgeSetFifoDart setFifo;
  late final MaBridgeStartDart start;
  late final MaBridgeStopDart stop;
  late final MaBridgeGetFramesConsumedDart getFramesConsumed;
  late final MaBridgeGetFifoAvailableDart getFifoAvailable;
  late final MaBridgeSetVolumeDart setVolume;
  late final MaBridgeGetDeviceSampleRateDart getDeviceSampleRate;
  late final MaBridgeGetDeviceChannelsDart getDeviceChannels;
  late final MaBridgeDeinitDart deinit;

  // Engine
  late final MaBridgeEngineInitDart engineInit;
  late final MaBridgeEngineUninitDart engineUninit;
  late final MaBridgeEngineStartDart engineStart;
  late final MaBridgeEngineStopDart engineStop;
  late final MaBridgeEngineSetVolumeDart engineSetVolume;
  late final MaBridgeEnginePlaySoundDart enginePlaySound;
  late final MaBridgeEngineGetEndpointDart engineGetEndpoint;

  // Sound
  late final MaBridgeSoundInitFromFileDart soundInitFromFile;
  late final MaBridgeSoundUninitDart soundUninit;
  late final MaBridgeSoundPlayDart soundPlay;
  late final MaBridgeSoundStopDart soundStop;
  late final MaBridgeSoundSetVolumeDart soundSetVolume;
  late final MaBridgeSoundSetPitchDart soundSetPitch;
  late final MaBridgeSoundSetPanDart soundSetPan;
  late final MaBridgeSoundSetLoopingDart soundSetLooping;
  late final MaBridgeSoundSetPositionDart soundSetPosition;
  late final MaBridgeSoundSetDirectionDart soundSetDirection;
  late final MaBridgeSoundSetVelocityDart soundSetVelocity;
  late final MaBridgeSoundSetConeDart soundSetCone;
  late final MaBridgeSoundSetDopplerFactorDart soundSetDopplerFactor;
  late final MaBridgeSoundSetFadeInPcmFramesDart soundSetFadeInPcmFrames;
  late final MaBridgeSoundSetFadeStartTimeDart soundSetFadeStartTime;
  late final MaBridgeSoundSeekToPcmFrameDart soundSeekToPcmFrame;
  late final MaBridgeSoundGetLengthInPcmFramesDart soundGetLengthInPcmFrames;
  late final MaBridgeSoundGetCursorInPcmFramesDart soundGetCursorInPcmFrames;
  late final MaBridgeSoundIsPlayingDart soundIsPlaying;
  late final MaBridgeSoundAtEndDart soundAtEnd;

  late final MaBridgeSoundInitFromMemoryDart soundInitFromMemory;
  late final MaBridgeSoundInitNoiseDart soundInitNoise;
  late final MaBridgeSoundInitWaveformDart soundInitWaveform;
  late final MaBridgeSoundRouteToNodeDart soundRouteToNode;

  // Listener
  late final MaBridgeEngineListenerSetPositionDart engineListenerSetPosition;
  late final MaBridgeEngineListenerSetDirectionDart engineListenerSetDirection;
  late final MaBridgeEngineListenerSetVelocityDart engineListenerSetVelocity;
  late final MaBridgeEngineListenerSetWorldUpDart engineListenerSetWorldUp;
  late final MaBridgeEngineListenerSetConeDart engineListenerSetCone;
  late final MaBridgeEngineListenerSetEnabledDart engineListenerSetEnabled;

  // Sound Group
  late final MaBridgeSoundGroupInitDart soundGroupInit;
  late final MaBridgeSoundGroupUninitDart soundGroupUninit;
  late final MaBridgeSoundGroupStartDart soundGroupStart;
  late final MaBridgeSoundGroupStopDart soundGroupStop;
  late final MaBridgeSoundGroupSetVolumeDart soundGroupSetVolume;
  late final MaBridgeSoundGroupSetPanDart soundGroupSetPan;
  late final MaBridgeSoundGroupSetPitchDart soundGroupSetPitch;

  late final MaBridgeSoundInitFromFileWithGroupDart soundInitFromFileWithGroup;

  // Nodes
  late final MaBridgeNodeUninitDart nodeUninit;
  late final MaBridgeNodeHpfInitDart nodeHpfInit;
  late final MaBridgeNodeHpfSetCutoffDart nodeHpfSetCutoff;

  late final MaBridgeNodeLpfInitDart nodeLpfInit;
  late final MaBridgeNodeLpfSetCutoffDart nodeLpfSetCutoff;

  late final MaBridgeNodeBpfInitDart nodeBpfInit;
  late final MaBridgeNodeBpfSetCutoffDart nodeBpfSetCutoff;

  late final MaBridgeNodeDelayInitDart nodeDelayInit;
  late final MaBridgeNodeDelaySetDelayDart nodeDelaySetDelay;
  late final MaBridgeNodeDelaySetWetDart nodeDelaySetWet;
  late final MaBridgeNodeDelaySetDryDart nodeDelaySetDry;
  late final MaBridgeNodeDelaySetDecayDart nodeDelaySetDecay;

  late final MaBridgeNodeReverbInitDart nodeReverbInit;
  late final MaBridgeNodeReverbSetParamsDart nodeReverbSetParams;

  late final MaBridgeNodePeakingEqInitDart nodePeakingEqInit;
  late final MaBridgeNodePeakingEqSetParamsDart nodePeakingEqSetParams;

  late final MaBridgeNodeLowShelfInitDart nodeLowShelfInit;
  late final MaBridgeNodeLowShelfSetParamsDart nodeLowShelfSetParams;

  late final MaBridgeNodeHighShelfInitDart nodeHighShelfInit;
  late final MaBridgeNodeHighShelfSetParamsDart nodeHighShelfSetParams;

  late final MaBridgeNodeSplitterInitDart nodeSplitterInit;
  late final MaBridgeNodeSplitterSetVolumeDart nodeSplitterSetVolume;

  late final MaBridgeNodeAttachOutputBusDart nodeAttachOutputBus;
  late final MaBridgeNodeDetachOutputBusDart nodeDetachOutputBus;

  MiniaudioBindings(this._lib) {
    // Context
    contextGetDeviceCount = _lib.lookupFunction<
            MaBridgeContextGetDeviceCountNative,
            MaBridgeContextGetDeviceCountDart>(
        'ma_bridge_context_get_device_count');
    contextGetDeviceInfo = _lib.lookupFunction<
        MaBridgeContextGetDeviceInfoNative,
        MaBridgeContextGetDeviceInfoDart>('ma_bridge_context_get_device_info');

    // Device
    init = _lib.lookupFunction<MaBridgeInitNative, MaBridgeInitDart>(
        'ma_bridge_init_with_device_id');
    setFifo = _lib.lookupFunction<MaBridgeSetFifoNative, MaBridgeSetFifoDart>(
        'ma_bridge_set_fifo');
    start = _lib.lookupFunction<MaBridgeStartNative, MaBridgeStartDart>(
        'ma_bridge_start');
    stop = _lib
        .lookupFunction<MaBridgeStopNative, MaBridgeStopDart>('ma_bridge_stop');
    getFramesConsumed = _lib.lookupFunction<MaBridgeGetFramesConsumedNative,
        MaBridgeGetFramesConsumedDart>('ma_bridge_get_frames_consumed');
    getFifoAvailable = _lib.lookupFunction<MaBridgeGetFifoAvailableNative,
        MaBridgeGetFifoAvailableDart>('ma_bridge_get_fifo_available');
    setVolume =
        _lib.lookupFunction<MaBridgeSetVolumeNative, MaBridgeSetVolumeDart>(
            'ma_bridge_set_volume');
    getDeviceSampleRate = _lib.lookupFunction<MaBridgeGetDeviceSampleRateNative,
        MaBridgeGetDeviceSampleRateDart>('ma_bridge_get_device_sample_rate');
    getDeviceChannels = _lib.lookupFunction<MaBridgeGetDeviceChannelsNative,
        MaBridgeGetDeviceChannelsDart>('ma_bridge_get_device_channels');
    deinit = _lib.lookupFunction<MaBridgeDeinitNative, MaBridgeDeinitDart>(
        'ma_bridge_deinit');

    // Engine
    engineInit =
        _lib.lookupFunction<MaBridgeEngineInitNative, MaBridgeEngineInitDart>(
            'ma_bridge_engine_init');
    engineUninit = _lib.lookupFunction<MaBridgeEngineUninitNative,
        MaBridgeEngineUninitDart>('ma_bridge_engine_uninit');
    engineStart =
        _lib.lookupFunction<MaBridgeEngineStartNative, MaBridgeEngineStartDart>(
            'ma_bridge_engine_start');
    engineStop =
        _lib.lookupFunction<MaBridgeEngineStopNative, MaBridgeEngineStopDart>(
            'ma_bridge_engine_stop');
    engineSetVolume = _lib.lookupFunction<MaBridgeEngineSetVolumeNative,
        MaBridgeEngineSetVolumeDart>('ma_bridge_engine_set_volume');
    enginePlaySound = _lib.lookupFunction<MaBridgeEnginePlaySoundNative,
        MaBridgeEnginePlaySoundDart>('ma_bridge_engine_play_sound');
    engineGetEndpoint = _lib.lookupFunction<MaBridgeEngineGetEndpointNative,
        MaBridgeEngineGetEndpointDart>('ma_bridge_engine_get_endpoint');

    // Sound
    soundInitFromFile = _lib.lookupFunction<MaBridgeSoundInitFromFileNative,
        MaBridgeSoundInitFromFileDart>('ma_bridge_sound_init_from_file');
    soundUninit =
        _lib.lookupFunction<MaBridgeSoundUninitNative, MaBridgeSoundUninitDart>(
            'ma_bridge_sound_uninit');
    soundPlay =
        _lib.lookupFunction<MaBridgeSoundPlayNative, MaBridgeSoundPlayDart>(
            'ma_bridge_sound_play');
    soundStop =
        _lib.lookupFunction<MaBridgeSoundStopNative, MaBridgeSoundStopDart>(
            'ma_bridge_sound_stop');
    soundSetVolume = _lib.lookupFunction<MaBridgeSoundSetVolumeNative,
        MaBridgeSoundSetVolumeDart>('ma_bridge_sound_set_volume');
    soundSetPitch = _lib.lookupFunction<MaBridgeSoundSetPitchNative,
        MaBridgeSoundSetPitchDart>('ma_bridge_sound_set_pitch');
    soundSetPan =
        _lib.lookupFunction<MaBridgeSoundSetPanNative, MaBridgeSoundSetPanDart>(
            'ma_bridge_sound_set_pan');
    soundSetLooping = _lib.lookupFunction<MaBridgeSoundSetLoopingNative,
        MaBridgeSoundSetLoopingDart>('ma_bridge_sound_set_looping');
    soundSetPosition = _lib.lookupFunction<MaBridgeSoundSetPositionNative,
        MaBridgeSoundSetPositionDart>('ma_bridge_sound_set_position');

    // New Advanced APIs
    soundSetDirection = _lib.lookupFunction<MaBridgeSoundSetDirectionNative,
        MaBridgeSoundSetDirectionDart>('ma_bridge_sound_set_direction');
    soundSetVelocity = _lib.lookupFunction<MaBridgeSoundSetVelocityNative,
        MaBridgeSoundSetVelocityDart>('ma_bridge_sound_set_velocity');
    soundSetCone = _lib.lookupFunction<MaBridgeSoundSetConeNative,
        MaBridgeSoundSetConeDart>('ma_bridge_sound_set_cone');
    soundSetDopplerFactor = _lib.lookupFunction<
            MaBridgeSoundSetDopplerFactorNative,
            MaBridgeSoundSetDopplerFactorDart>(
        'ma_bridge_sound_set_doppler_factor');
    soundSetFadeInPcmFrames = _lib.lookupFunction<
            MaBridgeSoundSetFadeInPcmFramesNative,
            MaBridgeSoundSetFadeInPcmFramesDart>(
        'ma_bridge_sound_set_fade_in_pcm_frames');
    soundSetFadeStartTime = _lib.lookupFunction<
            MaBridgeSoundSetFadeStartTimeNative,
            MaBridgeSoundSetFadeStartTimeDart>(
        'ma_bridge_sound_set_fade_start_time');
    soundSeekToPcmFrame = _lib.lookupFunction<MaBridgeSoundSeekToPcmFrameNative,
        MaBridgeSoundSeekToPcmFrameDart>('ma_bridge_sound_seek_to_pcm_frame');
    soundGetLengthInPcmFrames = _lib.lookupFunction<
            MaBridgeSoundGetLengthInPcmFramesNative,
            MaBridgeSoundGetLengthInPcmFramesDart>(
        'ma_bridge_sound_get_length_in_pcm_frames');
    soundGetCursorInPcmFrames = _lib.lookupFunction<
            MaBridgeSoundGetCursorInPcmFramesNative,
            MaBridgeSoundGetCursorInPcmFramesDart>(
        'ma_bridge_sound_get_cursor_in_pcm_frames');

    soundIsPlaying = _lib.lookupFunction<MaBridgeSoundIsPlayingNative,
        MaBridgeSoundIsPlayingDart>('ma_bridge_sound_is_playing');
    soundAtEnd =
        _lib.lookupFunction<MaBridgeSoundAtEndNative, MaBridgeSoundAtEndDart>(
            'ma_bridge_sound_at_end');

    soundInitFromMemory = _lib.lookupFunction<MaBridgeSoundInitFromMemoryNative,
        MaBridgeSoundInitFromMemoryDart>('ma_bridge_sound_init_from_memory');
    soundInitNoise = _lib.lookupFunction<MaBridgeSoundInitNoiseNative,
        MaBridgeSoundInitNoiseDart>('ma_bridge_sound_init_noise');
    soundInitWaveform = _lib.lookupFunction<MaBridgeSoundInitWaveformNative,
        MaBridgeSoundInitWaveformDart>('ma_bridge_sound_init_waveform');
    soundRouteToNode = _lib.lookupFunction<MaBridgeSoundRouteToNodeNative,
        MaBridgeSoundRouteToNodeDart>('ma_bridge_sound_route_to_node');

    // Listener
    engineListenerSetPosition = _lib.lookupFunction<
            MaBridgeEngineListenerSetPositionNative,
            MaBridgeEngineListenerSetPositionDart>(
        'ma_bridge_engine_listener_set_position');
    engineListenerSetDirection = _lib.lookupFunction<
            MaBridgeEngineListenerSetDirectionNative,
            MaBridgeEngineListenerSetDirectionDart>(
        'ma_bridge_engine_listener_set_direction');
    engineListenerSetVelocity = _lib.lookupFunction<
            MaBridgeEngineListenerSetVelocityNative,
            MaBridgeEngineListenerSetVelocityDart>(
        'ma_bridge_engine_listener_set_velocity');
    engineListenerSetWorldUp = _lib.lookupFunction<
            MaBridgeEngineListenerSetWorldUpNative,
            MaBridgeEngineListenerSetWorldUpDart>(
        'ma_bridge_engine_listener_set_world_up');
    engineListenerSetCone = _lib.lookupFunction<
            MaBridgeEngineListenerSetConeNative,
            MaBridgeEngineListenerSetConeDart>(
        'ma_bridge_engine_listener_set_cone');
    engineListenerSetEnabled = _lib.lookupFunction<
            MaBridgeEngineListenerSetEnabledNative,
            MaBridgeEngineListenerSetEnabledDart>(
        'ma_bridge_engine_listener_set_enabled');

    // Sound Group
    soundGroupInit = _lib.lookupFunction<MaBridgeSoundGroupInitNative,
        MaBridgeSoundGroupInitDart>('ma_bridge_sound_group_init');
    soundGroupUninit = _lib.lookupFunction<MaBridgeSoundGroupUninitNative,
        MaBridgeSoundGroupUninitDart>('ma_bridge_sound_group_uninit');
    soundGroupStart = _lib.lookupFunction<MaBridgeSoundGroupStartNative,
        MaBridgeSoundGroupStartDart>('ma_bridge_sound_group_start');
    soundGroupStop = _lib.lookupFunction<MaBridgeSoundGroupStopNative,
        MaBridgeSoundGroupStopDart>('ma_bridge_sound_group_stop');
    soundGroupSetVolume = _lib.lookupFunction<MaBridgeSoundGroupSetVolumeNative,
        MaBridgeSoundGroupSetVolumeDart>('ma_bridge_sound_group_set_volume');
    soundGroupSetPan = _lib.lookupFunction<MaBridgeSoundGroupSetPanNative,
        MaBridgeSoundGroupSetPanDart>('ma_bridge_sound_group_set_pan');
    soundGroupSetPitch = _lib.lookupFunction<MaBridgeSoundGroupSetPitchNative,
        MaBridgeSoundGroupSetPitchDart>('ma_bridge_sound_group_set_pitch');

    soundInitFromFileWithGroup = _lib.lookupFunction<
            MaBridgeSoundInitFromFileWithGroupNative,
            MaBridgeSoundInitFromFileWithGroupDart>(
        'ma_bridge_sound_init_from_file_with_group');

    // Nodes
    nodeUninit =
        _lib.lookupFunction<MaBridgeNodeUninitNative, MaBridgeNodeUninitDart>(
            'ma_bridge_node_uninit');

    nodeHpfInit =
        _lib.lookupFunction<MaBridgeNodeHpfInitNative, MaBridgeNodeHpfInitDart>(
            'ma_bridge_node_hpf_init');
    nodeHpfSetCutoff = _lib.lookupFunction<MaBridgeNodeHpfSetCutoffNative,
        MaBridgeNodeHpfSetCutoffDart>('ma_bridge_node_hpf_set_cutoff');

    nodePeakingEqInit = _lib.lookupFunction<MaBridgeNodePeakingEqInitNative,
        MaBridgeNodePeakingEqInitDart>('ma_bridge_node_peaking_eq_init');
    nodePeakingEqSetParams = _lib.lookupFunction<
            MaBridgeNodePeakingEqSetParamsNative,
            MaBridgeNodePeakingEqSetParamsDart>(
        'ma_bridge_node_peaking_eq_set_params');

    nodeLpfInit =
        _lib.lookupFunction<MaBridgeNodeLpfInitNative, MaBridgeNodeLpfInitDart>(
            'ma_bridge_node_lpf_init');
    nodeLpfSetCutoff = _lib.lookupFunction<MaBridgeNodeLpfSetCutoffNative,
        MaBridgeNodeLpfSetCutoffDart>('ma_bridge_node_lpf_set_cutoff');

    nodeBpfInit =
        _lib.lookupFunction<MaBridgeNodeBpfInitNative, MaBridgeNodeBpfInitDart>(
            'ma_bridge_node_bpf_init');
    nodeBpfSetCutoff = _lib.lookupFunction<MaBridgeNodeBpfSetCutoffNative,
        MaBridgeNodeBpfSetCutoffDart>('ma_bridge_node_bpf_set_cutoff');

    nodeDelayInit = _lib.lookupFunction<MaBridgeNodeDelayInitNative,
        MaBridgeNodeDelayInitDart>('ma_bridge_node_delay_init');
    nodeDelaySetDelay = _lib.lookupFunction<MaBridgeNodeDelaySetDelayNative,
        MaBridgeNodeDelaySetDelayDart>('ma_bridge_node_delay_set_delay');
    nodeDelaySetWet = _lib.lookupFunction<MaBridgeNodeDelaySetWetNative,
        MaBridgeNodeDelaySetWetDart>('ma_bridge_node_delay_set_wet');
    nodeDelaySetDry = _lib.lookupFunction<MaBridgeNodeDelaySetDryNative,
        MaBridgeNodeDelaySetDryDart>('ma_bridge_node_delay_set_dry');
    nodeDelaySetDecay = _lib.lookupFunction<MaBridgeNodeDelaySetDecayNative,
        MaBridgeNodeDelaySetDecayDart>('ma_bridge_node_delay_set_decay');

    nodeReverbInit = _lib.lookupFunction<MaBridgeNodeReverbInitNative,
        MaBridgeNodeReverbInitDart>('ma_bridge_node_reverb_init');
    nodeReverbSetParams = _lib.lookupFunction<MaBridgeNodeReverbSetParamsNative,
        MaBridgeNodeReverbSetParamsDart>('ma_bridge_node_reverb_set_params');

    nodeLowShelfInit = _lib.lookupFunction<MaBridgeNodeLowShelfInitNative,
        MaBridgeNodeLowShelfInitDart>('ma_bridge_node_low_shelf_init');
    nodeLowShelfSetParams = _lib.lookupFunction<
            MaBridgeNodeLowShelfSetParamsNative,
            MaBridgeNodeLowShelfSetParamsDart>(
        'ma_bridge_node_low_shelf_set_params');

    nodeHighShelfInit = _lib.lookupFunction<MaBridgeNodeHighShelfInitNative,
        MaBridgeNodeHighShelfInitDart>('ma_bridge_node_high_shelf_init');
    nodeHighShelfSetParams = _lib.lookupFunction<
            MaBridgeNodeHighShelfSetParamsNative,
            MaBridgeNodeHighShelfSetParamsDart>(
        'ma_bridge_node_high_shelf_set_params');

    nodeSplitterInit = _lib.lookupFunction<MaBridgeNodeSplitterInitNative,
        MaBridgeNodeSplitterInitDart>('ma_bridge_node_splitter_init');
    nodeSplitterSetVolume = _lib.lookupFunction<
            MaBridgeNodeSplitterSetVolumeNative,
            MaBridgeNodeSplitterSetVolumeDart>(
        'ma_bridge_node_splitter_set_volume');

    nodeAttachOutputBus = _lib.lookupFunction<MaBridgeNodeAttachOutputBusNative,
        MaBridgeNodeAttachOutputBusDart>('ma_bridge_node_attach_output_bus');
    nodeDetachOutputBus = _lib.lookupFunction<MaBridgeNodeDetachOutputBusNative,
        MaBridgeNodeDetachOutputBusDart>('ma_bridge_node_detach_output_bus');
  }
}
