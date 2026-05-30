Pod::Spec.new do |s|
    s.name             = 'atelerix_flutter'
    s.version          = '0.0.1'
    s.summary          = 'Atelerix Flutter Plugin'
    s.description      = 'Flutter plugin for Atelerix — error tracking, analytics, push notifications.'
    s.homepage         = 'https://atelerix.dev'
    s.license          = { :file => '../LICENSE' }
    s.author           = { 'Atelerix' => 'info@atelerix.dev' }
    s.source           = { :path => '.' }
  
    s.source_files     = 'Classes/**/*'
    s.public_header_files = 'Classes/**/*.h'
  
    s.dependency 'Flutter'
    s.platform = :ios, '13.0'
  
    s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
    s.swift_version = '5.0'
  end