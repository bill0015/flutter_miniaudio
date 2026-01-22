import 'dart:async';
import 'dart:ffi';
import 'dart:math';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_miniaudio/flutter_miniaudio.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  MiniaudioPlayer? _player;
  bool _isPlaying = false;
  Timer? _feedTimer;

  // Audio generation state
  double _phase = 0.0;
  final int _sampleRate = 48000;
  final double _frequency = 440.0; // A4 note

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  void _initPlayer() {
    try {
      _player = MiniaudioPlayer(
        sampleRate: _sampleRate,
        channels: 2,
        bufferFrames: 1024,
      );
      print('Miniaudio initialized');
    } catch (e) {
      print('Failed to init player: $e');
    }
  }

  void _togglePlay() {
    if (_player == null) return;

    if (_isPlaying) {
      _player!.stop();
      _feedTimer?.cancel();
      setState(() => _isPlaying = false);
    } else {
      _player!.start();
      setState(() => _isPlaying = true);

      // Start a "Game Loop" to feed audio
      // In a real app/game, this would be your main loop
      const frameDuration = Duration(milliseconds: 16); // ~60 FPS
      _feedTimer = Timer.periodic(frameDuration, (timer) {
        _generateAndFeedAudio();
      });
    }
  }

  /// Simulate a game core generating audio frame
  void _generateAndFeedAudio() {
    if (_player == null) return;

    // Generate ~16ms of audio (matches loop rate)
    // 48000 * 0.016 = 768 frames
    const int framesToGenerate = 768;

    // Allocate temporary native buffer
    final bufferSize = framesToGenerate * 2; // stereo
    final pointer = calloc<Int16>(bufferSize);

    // Generate Sine Wave
    for (int i = 0; i < framesToGenerate; i++) {
      final sample = (sin(_phase) * 10000).toInt(); // Amplitude 10000

      pointer[i * 2] = sample; // Left
      pointer[i * 2 + 1] = sample; // Right (mono to stereo)

      _phase += 2 * pi * _frequency / _sampleRate;
      if (_phase > 2 * pi) {
        _phase -= 2 * pi;
      }
    }

    // Write to Player (Pull-Mode FIFO)
    _player!.write(pointer, framesToGenerate);

    // Cleanup temp buffer
    calloc.free(pointer);

    // UI Update (Optional, just for debug)
    if (framesToGenerate % 60 == 0) {
      // Update occasionally
      // setState(() {});
    }
  }

  @override
  void dispose() {
    _feedTimer?.cancel();
    _player?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Miniaudio FFI Demo')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Low-Latency Audio Demo',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              if (_player != null)
                StreamBuilder(
                  stream: Stream.periodic(const Duration(milliseconds: 100)),
                  builder: (context, snapshot) {
                    return Text(
                      'Buffer Latency: ${(_player!.bufferLatency * 1000).toStringAsFixed(1)} ms\n'
                      'Frames Consumed: ${_player!.framesConsumed}',
                      textAlign: TextAlign.center,
                    );
                  },
                ),
              const SizedBox(height: 40),
              ElevatedButton.icon(
                onPressed: _togglePlay,
                icon: Icon(_isPlaying ? Icons.stop : Icons.play_arrow),
                label: Text(_isPlaying ? 'STOP Sine Wave' : 'PLAY Sine Wave'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
