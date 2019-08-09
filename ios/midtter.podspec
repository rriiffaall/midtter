#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#
Pod::Spec.new do |s|
  s.name             = 'midtter'
  s.version          = '0.0.1'
  s.summary          = 'midtrans X flutter.'
  s.description      = <<-DESC
midtrans X flutter.
                       DESC
  s.homepage         = 'http://example.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'RFL' => 'acc.rifal@gmail.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.public_header_files = 'Classes/**/*.h'
  s.dependency 'Flutter'
  s.dependency 'MidtransCoreKit'
  s.dependency 'MidtransKit'

  s.ios.deployment_target = '8.0'
end

