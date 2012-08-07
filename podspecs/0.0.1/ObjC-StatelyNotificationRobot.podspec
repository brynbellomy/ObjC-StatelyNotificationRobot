Pod::Spec.new do |s|
  s.name         = "ObjC-StatelyNotificationRobot"
  s.version      = "0.0.1"
  # s.summary      = "A short description of BrynKit."
  # s.homepage     = "http://github.com/brynbellomy/BrynKit" @@TODO: fix this thing here

  # s.author       = { "Bryn Austin Bellomy" => "bryn@signals.io" }
  # s.source       = { :git => "git://github.com/brynbellomy/ObjC-StatelyNotificationRobot" }
  s.source         = { :git => "/Users/bryn/repo/ObjC-StatelyNotificationRobot.git" }
  # s.platform     = :ios, '4.3'
  s.source_files = 'Classes/*.{h,m}'
  s.ios.deployment_target = '5.0'
  s.osx.deployment_target = '10.7'

  s.requires_arc = true
  s.xcconfig = { 'PUBLIC_HEADERS_FOLDER_PATH' => 'include/$(TARGET_NAME)' }

  
  s.dependency 'BrynKit'

end
