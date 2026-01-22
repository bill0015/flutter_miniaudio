# flutter_miniaudio

A high-performance, cross-platform low-latency audio plugin for Flutter, powered by [miniaudio](https://miniaudi.io/).

**Designed for Real-Time Applications**: Emulators, Games, VoIP, and Synthesizers.

---

## 📖 Core Principles: The "Audio Synchronization" Problem

### The Challenge: "Push" vs "Pull"
In standard Flutter audio plugins (like `audioplayers` or `flutter_soloud`), the workflow is typically **Push-Mode**:
1. Your Dart code generates or decodes audio.
2. You "push" this data to the native layer.
3. The native layer buffers it and plays it when ready.

**The Problem with Push-Mode in Real-Time Apps:**
*   **Clock Drift:** Your game loop runs on the system clock (Time), while the audio hardware runs on its own crystal oscillator (Sample Rate). These two clocks are never perfectly synchronized.
*   **The Result:** 
    *   If Dart is faster -> Buffer fills up -> **High Latency** (audio delays).
    *   If Dart is slower -> Buffer empties -> **Underrun** (crackling/glitching audio).
*   **Complex Fixes:** Developers often try to fix this by "blocking" the Dart thread when the buffer is full (using `sleep()`), but Dart is single-threaded (in the isolate), so accurate blocking is difficult and leads to inconsistent frame times.

### The Solution: "Pull-Mode" (Audio as Master)
`miniaudio_ffi` uses a **Pull-Mode** architecture, which is the industry standard for emulators (like RetroArch) and pro-audio tools:

1.  **Native Callback:** The OS audio driver (AAudio, CoreAudio, WASAPI) fires a high-priority callback whenever it needs more data. "I need 512 samples NOW."
2.  **Shared Memory Ring Buffer:** We use a lock-free Ring Buffer (FIFO) in shared memory between Dart and C.
3.  **The Flow:**
    *   **Native Side (Consumer):** Wakes up, grabs data from the Ring Buffer, and goes back to sleep. This happens at the *exact* hardware sample rate.
    *   **Dart Side (Producer):** You simply write to the Ring Buffer.

**Why this fixes Synchronization:**
Instead of trying to guess the timing, you simply check **"How full is the Ring Buffer?"**.
*   If the buffer is too full: **Wait**. (Throttle your game loop).
*   If the buffer is empty: **Speed up**. (Run the emulator faster).

This allows the **Audio Hardware** to act as the **Master Clock** for your entire application, ensuring perfect AV sync and zero latency.

---

## 🏗 Architecture

```mermaid
graph TD
    subgraph Dart Layer
    GL[Game Loop / Emulator] -->|Generate Int16 Samples| W[write()]
    W -->|Memcpy| RB_Dart[(Shared Ring Buffer)]
    end

    subgraph Native Layer (C)
    RB_Native[(Shared Ring Buffer)] --- RB_Dart
    Driver[Audio Driver\n(AAudio/CoreAudio/etc)] -->|Callback Request| CB[Data Callback]
    CB -->|Read from FIFO| RB_Native
    CB -->|PCM Data| Speaker
    end
```

*   **Zero-Copy (Almost):** Data is copied once from Dart to the Shared Ring Buffer. The Native side reads directly from this buffer.
*   **No JNI/MethodChannel Overhead:** Uses distinct `dart:ffi` calls for maximum performance.

---

## 🚀 Features

- **Extreme Low Latency**: Configurable buffer sizes (down to ~10ms).
- **Cross-Platform**:
  - 🤖 **Android**: AAudio (High Performance) with OpenSL ES fallback.
  - 🍎 **iOS/macOS**: CoreAudio / AudioUnit.
  - 🪟 **Windows**: WASAPI.
  - 🐧 **Linux**: ALSA / PulseAudio.
- **Lightweight**: No external dependencies. Just one compiled C library.
- **Simple API**: `start()`, `stop()`, `write()`, `dispose()`.

---

## 🛠 Usage

### 1. Installation
Add `miniaudio_ffi` to your `pubspec.yaml`:

```yaml
dependencies:
dependencies:
  flutter_miniaudio:
    git: https://github.com/Hibaogame/flutter_miniaudio.git
    # Or path if local:
    # path: packages/flutter_miniaudio
```

### 2. Basic Playback
```dart
import 'package:flutter_miniaudio/flutter_miniaudio.dart';
import 'dart:ffi'; // For Pointer operations

// 1. Initialize
final player = MiniaudioPlayer(
  sampleRate: 48000, // Standard sample rate
  channels: 2,       // Stereo
  bufferFrames: 1024 // Hardware buffer size (lower = less latency)
);

// 2. Start Device
player.start();

// 3. Generate and Write Audio (e.g., inside a loop)
// Get your audio data pointer (Pointer<Int16>)
player.write(audioDataPointer, frameCount);

// 4. Cleanup
player.dispose();
```

### 3. Implementing Audio Sync (The "Master Clock")
Here is how you sync your game loop to the audio:

```dart
void gameLoop() {
  // 1. Run one frame of the emulator/game
  emulator.runFrame();
  
  // 2. Push generated audio to the player
  player.write(emulator.audioPointer, emulator.audioFrames);
  
  // 3. Throttle Logic (The Magic)
  // Check how much audio is buffered. 
  // If we have more than 64ms buffered, we are running too fast!
  while (player.bufferLatency > 0.064) {
    // Wait a tiny bit to let the audio hardware catch up.
    // In a real app, you might sleep for 1ms.
    sleep(Duration(milliseconds: 1)); 
  }
}
```

---

## 🔧 API Reference

### `MiniaudioPlayer`

| Property/Method | Description |
|-----------------|-------------|
| `MiniaudioPlayer(...)` | Constructor. `bufferFrames` controls the hardware latency. `fifoCapacityFrames` controls the ring buffer size. |
| `start()` | Starts the audio device. |
| `stop()` | Pauses the audio device. |
| `write(Pointer<Int16>, int)` | Writes raw PCM samples to the ring buffer. returns frames written. |
| `writeList(List<int>)` | Helper to write from a Dart List (slower than Pointer). |
| `volume` | **Set** master volume (0.0 to 1.0). Default 1.0. |
| `deviceSampleRate` | **Get** actual hardware sample rate (e.g. 48000). Useful to detect resampling. |
| `deviceChannels` | **Get** actual hardware channel count. |
| `framesConsumed` | Total frames played since start. |
| `fifoAvailable` | How many samples can currently be written to the buffer. |
| `bufferLatency` | Current buffered duration in seconds (useful for sync). |
| `dispose()` | Stops device and frees native resources. |

---

## Advanced Usage: Audio Engine (Game Audio)

For games or UI sound effects, use `MiniaudioEngine`. It supports mixing, file playback, and 3D spatialization.

```dart
final engine = MiniaudioEngine();
engine.start();

// Fire-and-forget UI sound
engine.playOneShot("assets/click.wav");

// Music with control
final bgm = await engine.loadSound("assets/music.mp3");
bgm.looping = true;
bgm.volume = 0.5;
bgm.play();

// 3D Sound
final sfx = await engine.loadSound("assets/explosion.wav");
sfx.setPosition3D(10, 0, 0); // Right side
sfx.setFadeIn(0, 1.0, 48000); // 1-second fade in (if 48kHz)
sfx.play();
```

### API Reference - Engine

#### `MiniaudioEngine`
| API | Description |
| --- | --- |
| `start()` | Start the mixing engine. |
| `stop()` | Stop the engine. |
| `playOneShot(path)` | Play a sound file once and auto-release. |
| `loadSound(path)` | Load a sound object for advanced control. |

#### `MiniaudioSound`
| API | Description |
| --- | --- |
| `play()`, `stop()` | Control playback state. |
| `seekToFrame(int)` | Jump to specific PCM frame. |
| `volume`, `pitch`, `pan` | Basic properties. |
| `setPosition3D(x,y,z)` | Set 3D position of the sound source. |
| `setDirection(x,y,z)` | Set orientation of the sound source. |
| `setVelocity(x,y,z)` | Set velocity for Doppler effect. |
| `setFadeIn(beg,end,len)` | Automated volume fade. |
| `dispose()` | **Must call** to free native memory. |

#### `MiniaudioContext`
| API | Description |
| --- | --- |
| `getPlaybackDevices()` | List available output devices (names & IDs). |
| `getCaptureDevices()` | List available input devices. |

---

## Effects & Node Graph

Miniaudio supports a powerful node graph system. You can chain effects like EQ, High-Pass Filters, and Splitters.

### Basic Wiring
By default, sounds are connected to the Engine's endpoint (speakers). You can detach them and reconnect them to effects.

```dart
// 1. Create a Node (e.g., Peaking EQ)
final eq = engine.createPeakingEq();
eq.setParams(gainDB: 10, q: 1.0, frequency: 1000);

// 2. Route EQ to Speakers (Master)
eq.connectTo(engine.master);

// 3. Load Sound (it auto-connects to Master)
final sound = await engine.loadSound("music.mp3");

// 4. Re-route Sound -> EQ -> Master
sound.detach(); 
sound.connectTo(eq);

sound.play();
```

### Supported Nodes
*   `PeakingEqNode`: Parametric EQ band.
*   `LowShelfNode`: Low-end boost/cut.
*   `HighShelfNode`: High-end boost/cut.
*   `LowPassFilterNode` (`LPF`): Cuts high frequencies.
*   `HighPassFilterNode` (`HPF`): Cuts low frequencies.
*   `DelayNode`: Echo/Delay effect.
*   `ReverbNode`: Basic reverb effect.
*   `SplitterNode`: Split signal to multiple paths.

---

## 📝 License

MIT License. See [LICENSE](LICENSE) file.

Based on [miniaudio](https://github.com/mackron/miniaudio) by David Reid.
