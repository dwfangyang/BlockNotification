Pod::Spec.new do |s|

  s.name         = "BlockNotification"
  s.version      = "0.0.4"
  s.summary      = "observe notification with blocks for iOS"
  s.description  = <<-DESC
			observe notification with blocks for iOS
                   DESC
  s.homepage     = "https://github.com/dwfangyang/BlockNotification"
  s.license      = { :type => 'MIT', :text => 'LICENSE'}
  s.author       = { "perf" => "fangyang@yy.com" }
  s.platform     = :ios, "7.0"
  s.source       = { :git => "https://github.com/dwfangyang/BlockNotification.git", :tag => "#{s.version}" }
  
  s.requires_arc = ['BlockNotification/ARC/*.{h,m,mm,cpp}']
  s.source_files  = 'BlockNotification/ARC/*.{h,m,mm,cpp}','BlockNotification/Non_ARC/*.{h,m}'

end
