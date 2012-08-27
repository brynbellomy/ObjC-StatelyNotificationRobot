Pod::Spec.new do |s|
  s.name         = "ObjC-StatelyNotificationRobot"
  s.version      = "0.0.1"
  s.summary      = "NSNotification wrapper that keeps track of state and notifies new observers of state immediately. "
  s.homepage     = "http://brynbellomy.github.com/ObjC-StatelyNotificationRobot"

  s.author       = { "bryn austin bellomy" => "bryn.bellomy@gmail.com" }
  s.source       = { :git => "git://github.com/brynbellomy/ObjC-StatelyNotificationRobot" }
  s.source_files = 'Classes/*.{h,m}'

  s.requires_arc = true
  s.xcconfig = { 'PUBLIC_HEADERS_FOLDER_PATH' => 'include/$(TARGET_NAME)' }
  
  s.dependency "BrynKit"

end
