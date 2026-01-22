## 1.0.7
* Feature: Implemented Native Resampler (Linear) to handle input rate mismatches (e.g., 48002Hz -> 48000Hz).
* Feature: Implemented Dynamic Rate Control (P-Controller) to prevent audio buffer underruns/overruns.
* Feature: Added `setPlaybackSpeed` API for high-quality speed changes.
* Fix: Added back-pressure logic to `write_pcm_frames` for better audio sync.

## 1.0.6
* Fix: Removed `printf` debugging from real-time audio callback to prevent deadlocks.
* Fix: Implemented atomic ring buffer with memory barriers in C to prevent race conditions ("da da da" artifacts).
* Feat: Added `setLogEnabled(bool)` API to enable/disable native logging at runtime (default disabled).
## 1.0.5
* Fixed static analysis issues (curly braces in flow control structures).
* Removed unused prints and imports in example files.
* Corrected repository and homepage URLs in pubspec.yaml to align with metadata.

## 1.0.4
* Implemented Sound Generation: Noise and Waveforms.
* Implemented additional Effect Nodes: Delay, Low-Pass, High-Pass, and Band-Pass filters.
* Added memory-based sound loading support.
* Fixed C compilation errors for all platforms (macOS, iOS, Android, Linux, Windows).
* Resolved library loading issues on Apple platforms by renaming bridge entries to `.m`.
* Improved 3D audio API with Velocity, Direction, and Doppler Factor controls.

## 1.0.3
* Fixed lint warnings (dangling library doc comments).
* Corrected repository URL in pubspec.yaml.

## 1.0.2
* Documentation: Improved README with better examples and explanations.

## 1.0.1
* Documentation: Added complete list of supported nodes (Reverb, Delay, LPF, HPF) to README.
* Docs: Improved Chinese documentation.

## 1.0.0
* Major release. Renamed to `flutter_miniaudio`.
* Implemented low-latency "Pull-Mode" audio via RingBuffer.
* Added `MiniaudioEngine` for high-level audio management (mixing, 3D audio).
* Added Node Graph system with `PeakingEqNode`, `LowShelfNode`, `HighShelfNode`, `SplitterNode`.
* Added flexible graph wiring API (`connectTo`, `detach`).
* Supports Windows, macOS, Linux, Android, iOS.
