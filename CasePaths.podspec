Pod::Spec.new do |s|
  s.name             = 'CasePaths'
  s.version          = '0.1.0'
  s.summary          = 'A short description of CasePaths.'

  s.description      = <<-DESC
TODO: Add long description of the pod here.
                       DESC

  s.homepage         = 'https://github.com/AdiAyyakad/CasePaths'
  s.author           = { 'Aditya Ayyakad' => 'aditya.ayyakad@gmail.com' }
  s.source           = { :git => 'https://github.com/AdiAyyakad/CasePaths.git', :tag => s.version.to_s }

  s.ios.deployment_target = '11.0'
  s.source_files = 'Sources/**/*.swift'
  s.swift_version = '5.1'
end
