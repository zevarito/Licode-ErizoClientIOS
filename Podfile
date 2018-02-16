source 'https://github.com/CocoaPods/Specs.git'
use_frameworks!

platform :ios, :deployment_target => '8.0'

workspace './ErizoClientIOS.xcworkspace'

target 'ErizoClient' do
  platform :ios, :deployment_target => '8.0'
  project 'ErizoClientIOS'
  pod 'PodRTC', '65.8.0.0'
  pod 'Socket.IO-Client-Swift', '~> 12.0.0'
end

target 'ErizoClientTests' do
  platform :ios, :deployment_target => '8.0'
  inherit! :search_paths
  pod 'PodRTC', '65.8.0.0'
  pod 'Socket.IO-Client-Swift', '~> 12.0.0'
  pod 'OCMockito', '~> 4.0'
end

target 'ECIExampleLicode' do
  platform :ios, :deployment_target => '8.0'
  project 'ECIExampleLicode/ECIExampleLicode'
  pod 'PodRTC', '65.8.0.0'
  pod 'Socket.IO-Client-Swift', '~> 12.0.0'
end
