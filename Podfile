# Podfile for FengShuiLuopan
# 见 ARCHITECTURE.md 4.2节 - 依赖管理

platform :ios, '16.0'
use_frameworks!

target 'FengShuiLuopan' do
  # 高德地图SDK (3D地图 + 定位)
  # 官方文档: https://lbs.amap.com/api/ios-sdk/guide/create-project/cocoapods
  pod 'AMap3DMap', '~> 10.0'
  pod 'AMapLocation', '~> 2.10'

  # 注意: SQLite.swift使用SPM管理，不在Podfile中
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      # 确保所有Pod使用iOS 16.0+
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '16.0'

      # 禁用Bitcode (高德SDK不支持)
      config.build_settings['ENABLE_BITCODE'] = 'NO'
    end
  end
end
