/// Miniaudio - High-performance audio plugin for Flutter
///
/// Contains:
/// - MiniaudioPlayer: Low-latency pull-mode stream (for Emulators/VoIP)
/// - MiniaudioEngine: High-level mixing engine (for Games/UI)
/// - MiniaudioSound: Individual sound objects for the engine
/// - MiniaudioSoundGroup: Grouping for volume control/effects
/// - MiniaudioContext: Device enumeration
library;

import 'dart:ffi';
import 'dart:typed_data';
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'miniaudio_bindings.dart';

// --- Shared Bindings ---
MiniaudioBindings? _bindings;

void _ensureLibraryLoaded() {
  if (_bindings != null) return;

  final DynamicLibrary lib;
  if (Platform.isAndroid || Platform.isLinux) {
    lib = DynamicLibrary.open('libminiaudio_ffi.so');
  } else if (Platform.isIOS || Platform.isMacOS) {
    lib = DynamicLibrary.open('flutter_miniaudio.framework/flutter_miniaudio');
  } else if (Platform.isWindows) {
    lib = DynamicLibrary.open('miniaudio_ffi.dll');
  } else {
    throw UnsupportedError('Unsupported platform: ${Platform.operatingSystem}');
  }
  _bindings = MiniaudioBindings(lib);
}

// --- Data Types ---

enum MiniaudioDeviceType { playback, capture }

class MiniaudioDeviceInfo {
  final String name;
  final Pointer<Void> id; // Native ID handle
  final int index;

  MiniaudioDeviceInfo(
      {required this.name, required this.id, required this.index});
}

// --- Context (Enumeration) ---

class MiniaudioContext {
  /// Get list of available playback devices.
  static List<MiniaudioDeviceInfo> getPlaybackDevices() {
    return _getDevices(MiniaudioDeviceType.playback);
  }

  /// Get list of available capture devices.
  static List<MiniaudioDeviceInfo> getCaptureDevices() {
    return _getDevices(MiniaudioDeviceType.capture);
  }

  static List<MiniaudioDeviceInfo> _getDevices(MiniaudioDeviceType type) {
    _ensureLibraryLoaded();
    final typeInt = type == MiniaudioDeviceType.playback ? 0 : 1;
    final count = _bindings!.contextGetDeviceCount(typeInt);

    final List<MiniaudioDeviceInfo> devices = [];
    final nameBuffer = calloc<Uint8>(256).cast<Utf8>();
    const idBufferSize = 256;
    final idBuffer = calloc<Uint8>(idBufferSize);

    try {
      for (int i = 0; i < count; i++) {
        final result = _bindings!.contextGetDeviceInfo(
            typeInt, i, nameBuffer, 256, idBuffer.cast(), idBufferSize);
        if (result == 0) {
          final persistentId = calloc<Uint8>(idBufferSize);
          for (int j = 0; j < idBufferSize; j++) {
            persistentId[j] = idBuffer[j];
          }

          devices.add(MiniaudioDeviceInfo(
            name: nameBuffer.toDartString(),
            id: persistentId.cast(),
            index: i,
          ));
        }
      }
    } finally {
      calloc.free(nameBuffer);
      calloc.free(idBuffer);
    }
    return devices;
  }

  static void freeDevices(List<MiniaudioDeviceInfo> devices) {
    for (var d in devices) {
      calloc.free(d.id);
    }
  }
}

// --- Player (Device Stream) ---

/// Low-latency audio player using miniaudio with pull-mode callbacks.
class MiniaudioPlayer {
  late final Pointer<Int16> _fifoPtr;
  late final Pointer<Int32> _readPos;
  late final Pointer<Int32> _writePos;

  final int sampleRate;
  final int channels;
  final int bufferFrames;
  final int fifoCapacityFrames;
  final Pointer<Void>? deviceId;

  int get _fifoCapacitySamples => fifoCapacityFrames * channels;

  bool _initialized = false;
  bool _started = false;

  MiniaudioPlayer({
    required this.sampleRate,
    this.channels = 2,
    this.bufferFrames = 512,
    this.fifoCapacityFrames = 8192,
    this.deviceId, // Optional specific device
  }) {
    _ensureLibraryLoaded();
    _allocateBuffers();
    _initDevice();
  }

  void _allocateBuffers() {
    _fifoPtr = calloc<Int16>(_fifoCapacitySamples);
    _readPos = calloc<Int32>();
    _writePos = calloc<Int32>();
    _readPos.value = 0;
    _writePos.value = 0;
  }

  void _initDevice() {
    final result = _bindings!
        .init(deviceId ?? nullptr, sampleRate, channels, bufferFrames);
    if (result != 0) {
      throw Exception('Failed to initialize miniaudio device');
    }
    _bindings!.setFifo(_fifoPtr, _fifoCapacitySamples, _readPos, _writePos);
    _initialized = true;
  }

  void start() {
    if (!_initialized) throw StateError('MiniaudioPlayer not initialized');
    if (_started) return;
    if (_bindings!.start() != 0)
      throw Exception('Failed to start audio playback');
    _started = true;
  }

  void stop() {
    if (!_started) return;
    _bindings!.stop();
    _started = false;
  }

  int write(Pointer<Int16> data, int frames) {
    if (!_initialized) return 0;
    final samplesToWrite = frames * channels;
    final writeVal = _writePos.value;
    final readVal = _readPos.value;

    int freeSpace;
    if (writeVal >= readVal) {
      freeSpace = _fifoCapacitySamples - (writeVal - readVal) - 1;
    } else {
      freeSpace = readVal - writeVal - 1;
    }

    final actualSamples =
        samplesToWrite <= freeSpace ? samplesToWrite : freeSpace;
    if (actualSamples == 0) return 0;

    for (int i = 0; i < actualSamples; i++) {
      _fifoPtr[(writeVal + i) % _fifoCapacitySamples] = data[i];
    }
    _writePos.value = (writeVal + actualSamples) % _fifoCapacitySamples;
    return actualSamples ~/ channels;
  }

  int writeList(List<int> samples) {
    if (!_initialized) return 0;

    final writeVal = _writePos.value;
    final readVal = _readPos.value;
    int freeSpace = (writeVal >= readVal)
        ? _fifoCapacitySamples - (writeVal - readVal) - 1
        : readVal - writeVal - 1;

    final actualSamples =
        samples.length <= freeSpace ? samples.length : freeSpace;
    if (actualSamples == 0) return 0;

    for (int i = 0; i < actualSamples; i++) {
      _fifoPtr[(writeVal + i) % _fifoCapacitySamples] = samples[i];
    }
    _writePos.value = (writeVal + actualSamples) % _fifoCapacitySamples;
    return actualSamples ~/ channels;
  }

  int get framesConsumed => _bindings?.getFramesConsumed() ?? 0;
  int get fifoAvailable => _bindings?.getFifoAvailable() ?? 0;
  int get fifoAvailableFrames => fifoAvailable ~/ channels;
  double get bufferLatency => fifoAvailableFrames / sampleRate;
  bool get isPlaying => _started;
  set volume(double volume) => _bindings?.setVolume(volume);
  int get deviceSampleRate => _bindings?.getDeviceSampleRate() ?? 0;
  int get deviceChannels => _bindings?.getDeviceChannels() ?? 0;

  void dispose() {
    stop();
    if (_initialized) {
      _bindings!.deinit();
      _initialized = false;
    }
    calloc.free(_fifoPtr);
    calloc.free(_readPos);
    calloc.free(_writePos);
  }
}

// --- Engine (High Level) ---

abstract class GraphNode {
  Pointer<Void> get handle;

  /// Connect this node's output to another node's input.
  /// [outputBusIndex] defaults to 0 (MAIN).
  /// [inputBusIndex] defaults to 0 (MAIN).
  void connectTo(GraphNode destination,
      {int outputBusIndex = 0, int inputBusIndex = 0}) {
    _bindings!.nodeAttachOutputBus(
        handle, outputBusIndex, destination.handle, inputBusIndex);
  }

  /// Detach this node's output bus.
  void detach({int outputBusIndex = 0}) {
    _bindings!.nodeDetachOutputBus(handle, outputBusIndex);
  }
}

class MiniaudioEngine {
  bool _initialized = false;

  MiniaudioEngine() {
    _ensureLibraryLoaded();
    if (_bindings!.engineInit() != 0) {
      throw Exception("Failed to init engine");
    }
    _initialized = true;
  }

  void start() {
    _bindings!.engineStart();
  }

  void stop() {
    _bindings!.engineStop();
  }

  set volume(double value) {
    _bindings!.engineSetVolume(value);
  }

  void playOneShot(String path) {
    final pathPtr = path.toNativeUtf8();
    _bindings!.enginePlaySound(pathPtr);
    calloc.free(pathPtr);
  }

  /// Create (or get) the global listener.
  /// Currently miniaudio supports multiple listeners, but for most games 1 is enough.
  /// Index 0 is the default listener.
  AudioListener get listener => AudioListener._(0);

  /// Get the Master Endpoint node (Speakers).
  /// Use this to reconnect sounds/effects to the output after processing.
  GraphNode get master => _EndpointNode(_bindings!.engineGetEndpoint());

  /// Create a new Sound Group.
  MiniaudioSoundGroup createGroup([MiniaudioSoundGroup? parent]) {
    final handle = _bindings!.soundGroupInit(parent?._handle ?? nullptr);
    if (handle == nullptr) throw Exception("Failed to create sound group");
    return MiniaudioSoundGroup._(handle);
  }

  // --- Node Creation ---
  PeakingEqNode createPeakingEq() {
    final handle = _bindings!.nodePeakingEqInit();
    if (handle == nullptr) throw Exception("Failed to create Peaking EQ");
    return PeakingEqNode._(handle);
  }

  LowShelfNode createLowShelf() {
    final handle = _bindings!.nodeLowShelfInit();
    if (handle == nullptr) throw Exception("Failed to create Low Shelf");
    return LowShelfNode._(handle);
  }

  HighShelfNode createHighShelf() {
    final handle = _bindings!.nodeHighShelfInit();
    if (handle == nullptr) throw Exception("Failed to create High Shelf");
    return HighShelfNode._(handle);
  }

  SplitterNode createSplitter() {
    final handle = _bindings!.nodeSplitterInit();
    if (handle == nullptr) throw Exception("Failed to create Splitter");
    return SplitterNode._(handle);
  }

  DelayNode createDelay() {
    final handle = _bindings!.nodeDelayInit();
    if (handle == nullptr) throw Exception("Failed to create Delay");
    return DelayNode._(handle);
  }

  ReverbNode createReverb() {
    final handle = _bindings!.nodeReverbInit();
    if (handle == nullptr) throw Exception("Failed to create Reverb");
    return ReverbNode._(handle);
  }

  LowPassFilterNode createLowPass() {
    final handle = _bindings!.nodeLpfInit();
    if (handle == nullptr) throw Exception("Failed to create Low Pass Filter");
    return LowPassFilterNode._(handle);
  }

  HighPassFilterNode createHighPass() {
    final handle = _bindings!.nodeHpfInit();
    if (handle == nullptr) throw Exception("Failed to create High Pass Filter");
    return HighPassFilterNode._(handle);
  }

  BandPassFilterNode createBandPass() {
    final handle = _bindings!.nodeBpfInit();
    if (handle == nullptr) throw Exception("Failed to create Band Pass Filter");
    return BandPassFilterNode._(handle);
  }

  /// Create and load a sound object.
  /// Don't forget to call dispose() on the sound when done!
  Future<MiniaudioSound> loadSound(String path,
      {bool decode = false, MiniaudioSoundGroup? group}) async {
    final pathPtr = path.toNativeUtf8();
    int flags = decode ? 0x1 : 0x0;

    final handle = group != null
        ? _bindings!.soundInitFromFileWithGroup(pathPtr, group._handle, flags)
        : _bindings!.soundInitFromFile(pathPtr, flags);

    calloc.free(pathPtr);

    if (handle == nullptr) {
      throw Exception("Failed to load sound: $path");
    }
    return MiniaudioSound._(handle);
  }

  Future<MiniaudioSound> loadSoundFromMemory(Uint8List data,
      {bool decode = false}) async {
    final dataPtr = calloc<Uint8>(data.length);
    dataPtr.asTypedList(data.length).setAll(0, data);
    int flags = decode ? 0x1 : 0x0;

    final handle =
        _bindings!.soundInitFromMemory(dataPtr.cast(), data.length, flags);
    calloc.free(dataPtr);

    if (handle == nullptr) {
      throw Exception("Failed to load sound from memory");
    }
    return MiniaudioSound._(handle);
  }

  MiniaudioSound loadNoise(int type, {double amplitude = 0.5, int seed = 0}) {
    final handle = _bindings!.soundInitNoise(type, amplitude, seed);
    if (handle == nullptr) throw Exception("Failed to load noise");
    return MiniaudioSound._(handle);
  }

  MiniaudioSound loadWaveform(int type,
      {double amplitude = 0.5, double frequency = 440.0}) {
    final handle = _bindings!.soundInitWaveform(type, amplitude, frequency);
    if (handle == nullptr) throw Exception("Failed to load waveform");
    return MiniaudioSound._(handle);
  }

  void dispose() {
    if (_initialized) {
      _bindings!.engineUninit();
      _initialized = false;
    }
  }
}

class AudioListener {
  final int index;
  AudioListener._(this.index);

  void setPosition(double x, double y, double z) =>
      _bindings!.engineListenerSetPosition(index, x, y, z);
  void setDirection(double x, double y, double z) =>
      _bindings!.engineListenerSetDirection(index, x, y, z);
  void setVelocity(double x, double y, double z) =>
      _bindings!.engineListenerSetVelocity(index, x, y, z);
  void setWorldUp(double x, double y, double z) =>
      _bindings!.engineListenerSetWorldUp(index, x, y, z);
  void setCone(double innerAngle, double outerAngle, double outerGain) =>
      _bindings!
          .engineListenerSetCone(index, innerAngle, outerAngle, outerGain);

  /// Enable or disable spatialization calculation for this listener.
  void setEnabled(bool enabled) =>
      _bindings!.engineListenerSetEnabled(index, enabled ? 1 : 0);
}

class MiniaudioSoundGroup extends GraphNode {
  final Pointer<Void> _handle;
  MiniaudioSoundGroup._(this._handle);

  @override
  Pointer<Void> get handle => _handle;

  void start() => _bindings!.soundGroupStart(_handle);
  void stop() => _bindings!.soundGroupStop(_handle);

  set volume(double v) => _bindings!.soundGroupSetVolume(_handle, v);
  set pan(double v) => _bindings!.soundGroupSetPan(_handle, v);
  set pitch(double v) => _bindings!.soundGroupSetPitch(_handle, v);

  void dispose() {
    _bindings!.soundGroupUninit(_handle);
  }
}

class MiniaudioSound extends GraphNode {
  final Pointer<Void> _handle;

  MiniaudioSound._(this._handle);

  @override
  Pointer<Void> get handle => _handle;

  // --- Basic Control ---
  void play() => _bindings!.soundPlay(_handle);
  void stop() => _bindings!.soundStop(_handle);

  set volume(double v) => _bindings!.soundSetVolume(_handle, v);
  set pitch(double v) => _bindings!.soundSetPitch(_handle, v);
  set pan(double v) => _bindings!.soundSetPan(_handle, v); // -1.0 to 1.0

  set looping(bool loop) => _bindings!.soundSetLooping(_handle, loop ? 1 : 0);

  bool get isPlaying => _bindings!.soundIsPlaying(_handle) != 0;
  bool get isAtEnd => _bindings!.soundAtEnd(_handle) != 0;

  // --- Advanced Playback - Seek & Fade ---

  void seekToFrame(int frameIndex) {
    _bindings!.soundSeekToPcmFrame(_handle, frameIndex);
  }

  int get lengthFrames => _bindings!.soundGetLengthInPcmFrames(_handle);
  int get cursorFrames => _bindings!.soundGetCursorInPcmFrames(_handle);

  void setFadeIn(double volBeg, double volEnd, int lenFrames) {
    _bindings!.soundSetFadeInPcmFrames(_handle, volBeg, volEnd, lenFrames);
  }

  void setFadeStartTime(
      double volBeg, double volEnd, int lenFrames, int absoluteGlobalTime) {
    _bindings!.soundSetFadeStartTime(
        _handle, volBeg, volEnd, lenFrames, absoluteGlobalTime);
  }

  // --- Advanced Spatialization (3D) ---

  void setPosition3D(double x, double y, double z) {
    _bindings!.soundSetPosition(_handle, x, y, z);
  }

  void setDirection(double x, double y, double z) {
    _bindings!.soundSetDirection(_handle, x, y, z);
  }

  void setVelocity(double x, double y, double z) {
    _bindings!.soundSetVelocity(_handle, x, y, z);
  }

  void setCone(double innerAngle, double outerAngle, double outerGain) {
    _bindings!.soundSetCone(_handle, innerAngle, outerAngle, outerGain);
  }

  void setDopplerFactor(double factor) {
    _bindings!.soundSetDopplerFactor(_handle, factor);
  }

  void routeToNode(GraphNode? node) {
    _bindings!.soundRouteToNode(_handle, node?.handle ?? nullptr);
  }

  void dispose() {
    _bindings!.soundUninit(_handle);
  }
}

// --- Node Classes ---

// --- Node Classes ---

abstract class AudioNode extends GraphNode {
  final Pointer<Void> _handle;
  AudioNode._(this._handle);

  @override
  Pointer<Void> get handle => _handle;

  void dispose() {
    _bindings!.nodeUninit(_handle);
  }
}

class PeakingEqNode extends AudioNode {
  PeakingEqNode._(Pointer<Void> handle) : super._(handle);

  void setParams(
      {required double gainDB, required double q, required double frequency}) {
    _bindings!.nodePeakingEqSetParams(_handle, gainDB, q, frequency);
  }
}

class LowShelfNode extends AudioNode {
  LowShelfNode._(Pointer<Void> handle) : super._(handle);

  void setParams(
      {required double gainDB, required double q, required double frequency}) {
    _bindings!.nodeLowShelfSetParams(_handle, gainDB, q, frequency);
  }
}

class HighShelfNode extends AudioNode {
  HighShelfNode._(Pointer<Void> handle) : super._(handle);

  void setParams(
      {required double gainDB, required double q, required double frequency}) {
    _bindings!.nodeHighShelfSetParams(_handle, gainDB, q, frequency);
  }
}

class SplitterNode extends AudioNode {
  SplitterNode._(Pointer<Void> handle) : super._(handle);

  void setOutputVolume(int outputIndex, double volume) {
    _bindings!.nodeSplitterSetVolume(_handle, outputIndex, volume);
  }
}

class DelayNode extends AudioNode {
  DelayNode._(Pointer<Void> handle) : super._(handle);

  void setDelay(int delayMS) => _bindings!.nodeDelaySetDelay(_handle, delayMS);
  void setWet(double wet) => _bindings!.nodeDelaySetWet(_handle, wet);
  void setDry(double dry) => _bindings!.nodeDelaySetDry(_handle, dry);
  void setDecay(double decay) => _bindings!.nodeDelaySetDecay(_handle, decay);
}

class ReverbNode extends AudioNode {
  ReverbNode._(Pointer<Void> handle) : super._(handle);

  /// Note: Reverb is currently a placeholder if not supported by the bridge.
  void setParams(
      {double roomSize = 0.5,
      double damping = 0.5,
      double width = 1.0,
      double wet = 0.5,
      double dry = 0.5}) {
    _bindings!.nodeReverbSetParams(_handle, roomSize, damping, width, wet, dry);
  }
}

class LowPassFilterNode extends AudioNode {
  LowPassFilterNode._(Pointer<Void> handle) : super._(handle);
  void setCutoff(double frequency) =>
      _bindings!.nodeLpfSetCutoff(_handle, frequency);
}

class HighPassFilterNode extends AudioNode {
  HighPassFilterNode._(Pointer<Void> handle) : super._(handle);
  void setCutoff(double frequency) =>
      _bindings!.nodeHpfSetCutoff(_handle, frequency);
}

class BandPassFilterNode extends AudioNode {
  BandPassFilterNode._(Pointer<Void> handle) : super._(handle);
  void setCutoff(double frequency) =>
      _bindings!.nodeBpfSetCutoff(_handle, frequency);
}

class _EndpointNode extends GraphNode {
  final Pointer<Void> _handle;
  _EndpointNode(this._handle);
  @override
  Pointer<Void> get handle => _handle;
}
