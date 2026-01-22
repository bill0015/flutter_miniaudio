import 'dart:ffi';
import 'package:flutter/material.dart';
import 'package:flutter_miniaudio/flutter_miniaudio.dart';

void main() {
  runApp(const WiringDemoApp());
}

class WiringDemoApp extends StatefulWidget {
  const WiringDemoApp({super.key});

  @override
  State<WiringDemoApp> createState() => _WiringDemoAppState();
}

class _WiringDemoAppState extends State<WiringDemoApp> {
  late MiniaudioEngine _engine;
  MiniaudioSound? _sound;
  PeakingEqNode? _eqNode;

  bool _isEngineInit = false;
  bool _useEq = false;

  @override
  void initState() {
    super.initState();
    _initEngine();
  }

  Future<void> _initEngine() async {
    _engine = MiniaudioEngine();
    _engine.start();
    _isEngineInit = true;

    // Create EQ Node
    _eqNode = _engine.createPeakingEq();
    _eqNode!.setParams(gainDB: 10.0, q: 1.0, frequency: 1000.0);

    // Initial wiring: Sound -> Master (default behavior on load)
    // But we want to demonstrate RE-wiring.

    // Connect EQ to Master permanently for this demo
    _eqNode!.connectTo(_engine.master);

    setState(() {});
  }

  Future<void> _loadSound() async {
    if (_sound != null) return;

    // Replace with a valid path for testing on device
    // For now we assume a file exists or user provides one.
    // Using a dummy path might fail.
    // Ideally we bundle an asset. usage example: 'assets/test.mp3'
    // But since this is a code-only task, we'll implement logic assuming file exists
    // or just show how to do it.
    try {
      _sound = await _engine.loadSound("test_audio.mp3");
      // Default: Sound is connected to Endpoint.

      setState(() {});
    } catch (e) {
      print("Error loading sound: $e");
    }
  }

  void _toggleWiring() {
    if (_sound == null || _eqNode == null) return;

    if (_useEq) {
      // Switch back to Direct: Sound -> Master
      _sound!.detach(); // Detach from EQ
      _sound!.connectTo(_engine.master);
      _useEq = false;
    } else {
      // Switch to EQ: Sound -> EQ -> Master
      _sound!.detach(); // Detach from Master
      _sound!.connectTo(_eqNode!);
      _useEq = true;
    }
    setState(() {});
  }

  @override
  void dispose() {
    _sound?.dispose();
    _eqNode?.dispose();
    _engine.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Node Wiring Demo')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (!_isEngineInit) const CircularProgressIndicator(),
              if (_isEngineInit) ...[
                Text("Engine Running"),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _loadSound,
                  child: Text(_sound == null
                      ? "Load Sound (test_audio.mp3)"
                      : "Sound Loaded"),
                ),
                if (_sound != null) ...[
                  SizedBox(height: 20),
                  Text(
                      "Current Route: ${_useEq ? 'Sound -> EQ -> Master' : 'Sound -> Master'}"),
                  SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: _toggleWiring,
                    child: Text("Switch Route"),
                  ),
                  SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () => _sound!.play(),
                    child: Text("Play"),
                  ),
                ]
              ]
            ],
          ),
        ),
      ),
    );
  }
}
