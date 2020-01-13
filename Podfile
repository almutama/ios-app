install! 'cocoapods',
:generate_multiple_pod_projects => true,
:incremental_installation => true

platform :ios, '11.0'
source 'https://github.com/CocoaPods/Specs.git'

def mixin_services
  pod 'libsignal-protocol-c', :git => 'https://github.com/wuyuehyang/libsignal-protocol-c.git'
  pod 'WCDB.swift', :git => 'https://github.com/MixinNetwork/wcdb.git', :branch => 'bugfix/fts'
  pod 'MixinServices', :path => './MixinServices'
end

target 'Mixin' do
  use_frameworks!
  inhibit_all_warnings!

  pod 'Alamofire'
  pod 'SDWebImage'
  pod 'SDWebImageYYPlugin/YYImage'
  pod 'YYImage/WebP'
  pod 'SnapKit'
  pod 'PhoneNumberKit'
  pod 'RSKImageCropper'
  pod 'Zip', '~> 1.1.0'
  pod 'GoogleWebRTC'
  pod 'AlignedCollectionViewFlowLayout'
  pod 'R.swift'
  pod 'SwiftyMarkdown'
  mixin_services
end

target 'MixinNotificationService' do
  use_frameworks!
  inhibit_all_warnings!
  
  mixin_services
end
