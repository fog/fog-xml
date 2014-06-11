# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'fog/xml/version'

Gem::Specification.new do |spec|
  spec.name          = "fog-xml"
  spec.version       = Fog::Xml::VERSION
  spec.authors       = %q(Paulo Henrique Lopes Ribeiro)
  spec.email         = %q(plribeiro3000@gmail.com)
  spec.summary       = %q{XML parsing for fog providers}
  spec.description   = %q{Extraction of the XML parsing tools shared between a
                          number of providers in the 'fog' gem}
  spec.homepage      = 'https://github.com/zertico/fog-xml'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = %w(lib)

  spec.add_dependency 'fog-core'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rspec'
end
