#
# Be sure to run `pod lib lint SwiftyTraverson.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = "SwiftyTraverson"
  s.version          = "1.0.0-SNAPSHOT"
  s.summary          = "Swift implementation of a Hypermedia API/HATEOAS client."

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!  
  s.description      = <<-DESC
                       DESC

  s.homepage         = "https://github.com/smoope/SwiftyTraverson"
  s.license          = 'Apache License, Version 2.0'
  s.author           = { "Victor Mosin" => "victor@smoope.com" }
  s.source           = { :git => "https://github.com/smoope/SwiftyTraverson.git", :tag => s.version.to_s }

  s.platform     = :ios, '8.0'
  s.requires_arc = true

  s.source_files = 'Pod/Classes/**/*'
  s.resource_bundles = {
    'SwiftyTraverson' => ['Pod/Assets/*.png']
  }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  s.dependency 'Alamofire', '~> 3.0'
  s.dependency 'SwiftyJSON'
  s.dependency 'URITemplate'
end
