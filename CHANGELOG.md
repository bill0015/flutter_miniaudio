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
