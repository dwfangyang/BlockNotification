Pod::Spec.new do |s|

  s.name         = "BlockNotification"
  s.version      = "0.0.1"
  s.summary      = "observe notification with blocks for iOS"
  s.description  = <<-DESC
			observe notification with blocks for iOS
                   DESC
  s.homepage     = "https://github.com/dwfangyang/BlockNotification"
  s.license      = { :type => 'MIT', :text => 'LICENSE'}
  s.author       = { "perf" => "fangyang@yy.com" }
  s.platform     = :ios, "7.0"
  s.source       = { :git => "https://github.com/dwfangyang/BlockNotification.git", :tag => "#{s.version}" }
  
  s.requires_arc = true
  s.source_files  = 'BlockNotification/*.{h,m,mm,cpp},{ 'BlockNotification/BNLeakChecker.{h,m}' => { requires_arc: false }'

end
