Pod::Spec.new do |spec|

  spec.name         = "Refresher_Swift"
  spec.version      = "1.1"
  spec.summary      = "A pull-to-refresh component that can customize animation according to the pull-down state."
  spec.homepage     = "https://github.com/zyvv/Refresher"
  spec.license      = "MIT"
  spec.author       = { "zyvv" => "zhangyangv@foxmail.com" }
  spec.platform     = :ios, "11.0"
  spec.source       = { :git => "https://github.com/zyvv/Refresher.git", :tag => "#{spec.version}" }
  spec.source_files  = "Sources/*.swift"
  spec.swift_versions = "5.0"
end
