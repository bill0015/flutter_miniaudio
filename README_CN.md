# flutter_miniaudio (中文文档)

基于 [miniaudio](https://miniaudi.io/) 构建的高性能、跨平台 Flutter 低延迟音频插件。

**专为实时应用设计**：模拟器、游戏、VoIP 和合成器。

---

## 📖 核心原理：解决“音频同步”问题

### 挑战：“推模式 (Push)” vs “拉模式 (Pull)”
标准的 Flutter 音频插件（如 `audioplayers` 或 `flutter_soloud`）通常使用 **推模式 (Push-Mode)**：
1. Dart 代码生成或解码音频数据。
2. 将数据“推”送到原生层。
3. 原生层进行缓冲并在准备好时播放。

**推模式在实时应用中的问题：**
*   **时钟漂移 (Clock Drift)：** 你的游戏循环运行在系统时钟（Time）上，而音频硬件运行在自己的晶振时钟（Sample Rate）上。这两个时钟永远无法完美同步。
*   **后果：** 
    *   如果 Dart 跑得太快 -> 缓冲区堆积 -> **高延迟** (声音滞后)。
    *   如果 Dart 跑得太慢 -> 缓冲区耗尽 -> **爆音/卡顿** (Underrun)。
*   **复杂的修复：** 开发者通常尝试在 Dart 中使用 `sleep()` 来阻塞线程以等待缓冲区消耗，但 Dart 是单线程模型（isolate），精确阻塞非常困难，会导致帧率不稳定。

### 解决方案：“拉模式 (Pull-Mode)” (音频作为主时钟)
`miniaudio_ffi` 采用了 **拉模式** 架构，这是模拟器（如 RetroArch）和专业音频工具的行业标准：

1.  **原生回调 (Native Callback)：** 操作系统音频驱动 (AAudio, CoreAudio, WASAPI) 会在需要数据时触发高优先级回调。“我现在需要 512 个采样。”
2.  **共享内存环形缓冲区 (Ring Buffer)：** 我们在 Dart 和 C 之间使用一个无锁环形缓冲区 (FIFO)。
3.  **流程：**
    *   **原生端 (消费者)：** 唤醒，从环形缓冲区读取数据，然后休眠。这严格按照硬件采样率发生。
    *   **Dart 端 (生产者)：** 你只需要往环形缓冲区写入数据。

**为什么这能解决同步问题：**
你不需要猜测时间，只需要检查 **“环形缓冲区有多满？”**。
*   如果缓冲区太满：**等待 (Wait)**。（让游戏循环慢下来）
*   如果缓冲区空了：**加速 (Speed up)**。（让模拟器跑快点）

这使得 **音频硬件** 成为你整个应用的 **主时钟 (Master Clock)**，从而确保完美的音画同步和零延迟。

---

## 🏗 架构图

**Dart 层:**
1.  `游戏循环 / 模拟器` → 生成 Int16 采样 → `write()` → 拷贝数据到 **共享环形缓冲区**。

**原生层 (C):**
1.  `音频驱动 (AAudio/CoreAudio/etc)` → 触发回调 → `数据回调` → 从 **共享环形缓冲区** 读取 → 输出 PCM 数据到 **扬声器**。

*   **零拷贝 (接近)：** 数据只从 Dart 拷贝一次到共享环形缓冲区。原生端直接读取此缓冲区。
*   **无 JNI/MethodChannel 开销：** 使用纯 `dart:ffi` 调用，性能最大化。

---

## 🚀 特性

- **极低延迟**：可配置缓冲区大小（低至 ~10ms）。
- **跨平台支持**：
  - 🤖 **Android**: AAudio (高性能) / OpenSL ES (兼容)。
  - 🍎 **iOS/macOS**: CoreAudio / AudioUnit。
  - 🪟 **Windows**: WASAPI。
  - 🐧 **Linux**: ALSA / PulseAudio。
- **轻量级**：无外部依赖。仅编译一个 C 头文件库。
- **简单 API**：`start()`, `stop()`, `write()`, `dispose()`。

---

## 🛠 使用方法

### 1. 安装依赖
在 `pubspec.yaml` 中添加 `miniaudio_ffi`:

```yaml
dependencies:
dependencies:
  flutter_miniaudio:
    git: https://github.com/bill0015/flutter_miniaudio.git
    # 如果是本地路径：
    # path: packages/flutter_miniaudio
```

### 2. 基本播放
```dart
import 'package:flutter_miniaudio/flutter_miniaudio.dart';
import 'dart:ffi'; // 用于 Pointer 操作

// 1. 初始化
final player = MiniaudioPlayer(
  sampleRate: 48000, // 标准采样率
  channels: 2,       // 立体声
  bufferFrames: 1024 // 硬件缓冲区大小 (越小延迟越低)
);

// 2. 启动设备
player.start();

// 3. 生成并写入音频 (例如在循环中)
// 获取你的音频数据指针 (Pointer<Int16>)
player.write(audioDataPointer, frameCount);

// 4. 清理
player.dispose();
```

### 3. 实现音频同步 (作为主时钟)
以下是如何将游戏循环通过音频进行同步：

```dart
void gameLoop() {
  // 1. 运行一帧模拟器/游戏
  emulator.runFrame();
  
  // 2. 将生成的音频推送到播放器
  player.write(emulator.audioPointer, emulator.audioFrames);
  
  // 3. 节流逻辑 (关键点)
  // 检查缓冲区积压了多少音频。
  // 如果积压超过 64ms，说明模拟器跑得比音频硬件快！
  while (player.bufferLatency > 0.064) {
    // 等待一小会儿，让音频硬件消耗掉一些数据。
    // 在真实应用中，你可能会 sleep 1ms。
    sleep(Duration(milliseconds: 1)); 
  }
}
```

---

## 🔧 API 参考

### `MiniaudioPlayer`

| 属性/方法 | 描述 |
|-----------------|-------------|
| `MiniaudioPlayer(...)` | 构造函数。`bufferFrames` 控制硬件延迟。`fifoCapacityFrames` 控制环形缓冲区大小。 |
| `start()` | 启动音频设备。 |
| `stop()` | 暂停音频设备。 |
| `write(Pointer<Int16>, int)` | 将原始 PCM 采样写入环形缓冲区。返回实际写入的帧数。 |
| `writeList(List<int>)` | 辅助方法，从 Dart List 写入 (比 Pointer 慢)。 |
| `volume` | **设置** 主音量 (0.0 到 1.0). 默认为 1.0。 |
| `deviceSampleRate` | **获取** 实际硬件采样率 (如 48000)。用于检测是否发生重采样。 |
| `deviceChannels` | **获取** 实际硬件声道数。 |
| `framesConsumed` | 自启动以来播放的总帧数。 |
| `fifoAvailable` | 当前可以写入多少采样数据。 |
| `fifoAvailableFrames` | 当前可以写入多少帧数据。 |
| `bufferLatency` | 当前缓冲区积压的时长（秒），用于同步控制。 |
| `dispose()` | 停止设备并释放原生资源。 |

---

## 进阶用法: 音频引擎 (游戏音效)

对于游戏或 UI 音效，一般使用 `MiniaudioEngine`。它支持多轨混音、文件播放和 3D 空间音效。

```dart
final engine = MiniaudioEngine();
engine.start();

// 播放即忘的 UI 音效
engine.playOneShot("assets/click.wav");

// 播放背景音乐 (支持循环和控制)
final bgm = await engine.loadSound("assets/music.mp3");
bgm.looping = true;
bgm.volume = 0.5;
bgm.play();

// 3D 音效示例
final sfx = await engine.loadSound("assets/explosion.wav");
sfx.setPosition3D(10, 0, 0); // 在听者右侧
sfx.setFadeIn(0, 1.0, 48000); // 1秒钟淡入 (假设采样率48k)
sfx.play();
```

### API 参考 - 引擎 (Engine)

#### `MiniaudioEngine`
| API | 描述 |
| --- | --- |
| `start()` | 启动混音引擎。 |
| `stop()` | 停止引擎。 |
| `playOneShot(path)` | 播放一次性音效文件，自动释放。 |
| `loadSound(path)` | 加载声音对象以进行精细控制。 |

#### `MiniaudioSound`
| API | 描述 |
| --- | --- |
| `play()`, `stop()` | 控制播放状态。 |
| `seekToFrame(int)` | 跳转到指定 PCM 帧位置。 |
| `volume`, `pitch`, `pan` | 基础属性控制。 |
| `setPosition3D(x,y,z)` | 设置声源的 3D 空间位置。 |
| `setDirection(x,y,z)` | 设置声源的朝向。 |
| `setVelocity(x,y,z)` | 设置声源速度 (用于多普勒效应)。 |
| `setFadeIn(beg,end,len)` | 自动音量淡入淡出。 |
| `dispose()` | **必须调用** 以释放原生内存。 |

#### `MiniaudioContext`
| API | 描述 |
| --- | --- |
| `getPlaybackDevices()` | 获取可用输出设备列表 (包含名称和 ID)。 |
| `getCaptureDevices()` | 获取可用输入设备列表。 |

---

## 特效与节点图 (Effects & Node Graph)

Miniaudio 支持强大的节点图系统。您可以串联 EQ、高通滤波器和分频器等特效。

### 基础连线 (Wiring)
默认情况下，声音直接连接到引擎的终点（扬声器）。您可以将其断开并重新连接到特效节点。

```dart
// 1. 创建节点 (例如 Peaking EQ)
final eq = engine.createPeakingEq();
eq.setParams(gainDB: 10, q: 1.0, frequency: 1000);

// 2. 将 EQ 连接到扬声器 (Master)
eq.connectTo(engine.master);

// 3. 加载声音 (默认自动连接到 Master)
final sound = await engine.loadSound("music.mp3");

// 4. 重新路由: Sound -> EQ -> Master
sound.detach(); 
sound.connectTo(eq);

sound.play();
```

### 支持的节点
*   `PeakingEqNode`: 参量均衡器。
*   `LowShelfNode`: 低频架式滤波器。
*   `HighShelfNode`: 高频架式滤波器。
*   `LowPassFilterNode` (`LPF`): 低通滤波器 (削减高频)。
*   `HighPassFilterNode` (`HPF`): 高通滤波器 (削减低频)。
*   `DelayNode`: 延迟/回声节点。
*   `ReverbNode`: 混响节点。
*   `SplitterNode`: 信号分离器 (通过 `connectTo(..., inputBusIndex)` 连接到不同输入)。

---

## 📝 许可证

MIT License. 详见 [LICENSE](LICENSE) 文件。
基于 David Reid 的 [miniaudio](https://github.com/mackron/miniaudio) 开发。
