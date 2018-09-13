Pod::Spec.new do |s|

  s.name         = "BlockNotification"
  s.version      = "0.0.1"
  s.summary      = "observe notification with blocks for iOS"
  s.description  = <<-DESC
			observe notification with blocks for iOS
                   DESC
  s.homepage     = "https://git.yy.com/fangyang/BlockNotification"
  s.license      = { :type => 'MIT', :text => 'LICENSE'}
  s.author       = { "perf" => "fangyang@yy.com" }
  s.platform     = :ios, "7.0"
  s.source       = { :git => "https://git.yy.com/fangyang/BlockNotification.git", :tag => "#{s.version}" }
  
  s.subspec 'no-ARC' do |ss|
  	ss.requires_arc = false
	ss.source_files  = 'BlockNotification/BNLeakChecker.{h,m}'
  end
  s.subspec 'ARC' do |ss|
  	ss.requires_arc = true
	ss.source_files  = 'BlockNotification/*.{h,m,mm,cpp}'
  	ss.exclude_files = 'BlockNotification/BNLeakChecker.{h,m}'
  end

end