#
# Be sure to run `pod lib lint SwiftyTraverson.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = "SwiftyTraverson"
  s.version          = "1.1.1"
  s.summary          = "Swift implementation of a Hypermedia API/HATEOAS client."

  s.description      = <<-DESC
Traverson allows you to follow the relation links within the HATEOAS-based API's response instead of harcoding every single url.
In addition, the built-in features allow you:
- manage header info sent to server
- handle URI tempalte variables
- use different types of authentication
                       DESC

  s.homepage         = "https://github.com/smoope/SwiftyTraverson"
  s.license          = 'Apache License, Version 2.0'
  s.author           = { "Victor Mosin" => "victor@smoope.com", "Steve Maahs" => "steve.maahs@piobyte.de" }
  s.source           = { :git => "https://github.com/smoope/SwiftyTraverson.git", :tag => s.version.to_s }

  s.platform     = :ios, '8.0'
  s.requires_arc = true

  s.source_files = 'Pod/Classes/**/*'

  s.dependency 'Alamofire', '~> 4.0'
  s.dependency 'SwiftyJSON', '~> 3.0'
  s.dependency 'URITemplate', '~> 2.0'
end
