Pod::Spec.new do |spec|
  spec.license                = 'MIT'
  spec.platform               = 'ios', '8.4'
  spec.version                = '4.5.2'
  spec.name                   = 'LicodeErizoClient'
  spec.summary                = 'iOS Client for Licode WebRTC framework'
  spec.authors                = { 'Alvaro Gil' => 'zevarito@gmail.com' }
  spec.homepage               = 'https://github.com/zevarito/Licode-ErizoClientIOS'
  spec.source                 = { git: 'https://github.com/zevarito/Licode-ErizoClientIOS.git', tag: '4.5.2' }
  spec.source_files           = [ 'ErizoClient/**/*.{h,m}', 'Vendor/**/*.{h,m}' ]
  spec.dependency             'PodRTC', '61.4.0.0'
  spec.dependency             'Socket.IO-Client-Swift', '12.0.0'
  spec.dependency             'OCMockito', '~> 4.0'
  spec.libraries              = 'icucore'
  spec.pod_target_xcconfig   = {
    'ENABLE_BITCODE' => 'NO',
    'SWIFT_VERSION' => '4.0',
    'VALID_ARCHS' => 'x86_64 arm64'
  }
end
