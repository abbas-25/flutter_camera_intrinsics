#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint camera_intrinsics.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'camera_intrinsics'
  s.version          = '0.0.1'
  s.summary          = 'Flutter plugin to retrieve camera intrinsics using ARKit.'
  s.description      = <<-DESC
A Flutter plugin to retrieve camera intrinsics (focal length, principal point, image dimensions) using ARKit.
                       DESC
  s.homepage         = 'https://github.com/abbas-25/camera_intrinsics'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Abbas' => 'email@example.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '13.0'
  s.frameworks = 'ARKit'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'

  # If your plugin requires a privacy manifest, for example if it uses any
  # required reason APIs, update the PrivacyInfo.xcprivacy file to describe your
  # plugin's privacy impact, and then uncomment this line. For more information,
  # see https://developer.apple.com/documentation/bundleresources/privacy_manifest_files
  # s.resource_bundles = {'camera_intrinsics_privacy' => ['Resources/PrivacyInfo.xcprivacy']}
end
