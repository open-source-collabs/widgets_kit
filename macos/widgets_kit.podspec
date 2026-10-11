#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint widgets_kit.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'widgets_kit'
  s.version          = '0.1.1'
  s.summary          = 'Connects a Flutter app to native home screen widgets.'
  s.description      = <<-DESC
Send data from Flutter to native home screen widgets and refresh them.
                       DESC
  s.homepage         = 'https://github.com/open-source-collabs/widgets_kit'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'widgets_kit' => 'https://github.com/open-source-collabs/widgets_kit' }
  s.source           = { :path => '.' }
  s.source_files     = 'widgets_kit/Sources/widgets_kit/**/*'
  s.dependency 'FlutterMacOS'
  s.platform = :osx, '10.15'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
  s.swift_version = '5.0'
end
