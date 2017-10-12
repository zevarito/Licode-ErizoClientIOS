use_frameworks!

platform :ios, :deployment_target => '8.0'

workspace './ErizoClientIOS.xcworkspace'

target 'ErizoClient' do
  platform :ios, :deployment_target => '8.0'
  project 'ErizoClientIOS'
  pod 'PodRTC', '58.19.0.1'
  pod 'Socket.IO-Client-Swift', '~> 11.1.2'
end

target 'ErizoClientTests' do
  platform :ios, :deployment_target => '8.0'
  inherit! :search_paths
  pod 'PodRTC', '58.19.0.1'
  pod 'Socket.IO-Client-Swift', '~> 11.1.2'
  pod 'OCMockito', '~> 4.0'
end

target 'ECIExampleLicode' do
  platform :ios, :deployment_target => '8.0'
  project 'ECIExampleLicode/ECIExampleLicode'
  pod 'PodRTC', '58.19.0.1'
  pod 'Socket.IO-Client-Swift', '~> 11.1.2'
end
