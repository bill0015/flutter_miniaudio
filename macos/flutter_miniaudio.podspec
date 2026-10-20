Pod::Spec.new do |s|
  s.name             = 'flutter_miniaudio'
  s.version          = '0.0.1'
  s.summary          = 'Cross-platform low-latency audio plugin.'
  s.description      = <<-DESC
A new Flutter FFI plugin project for miniaudio.
                       DESC
  s.homepage         = 'http://example.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'email@example.com' }

  # This will ensure the source files in Sources/ are included in the native
  # builds of apps using this FFI plugin. Podspec does not support relative
  # paths, so Sources contains a forwarder C file that relatively imports
  # `../src/*` so that the C sources can be shared among all target platforms.
  s.source           = { :path => '.' }
  s.source_files = 'flutter_miniaudio/Sources/flutter_miniaudio/**/*.{c,m,mm,h}'
  s.frameworks = 'AudioToolbox', 'CoreAudio', 'CoreFoundation', 'AVFoundation'

  s.dependency 'FlutterMacOS'

  s.platform = :osx, '10.13'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
  s.swift_version = '5.0'
end
