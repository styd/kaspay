# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'kaspay/version'

Gem::Specification.new do |spec|
  spec.name          = "kaspay"
  spec.version       = KasPay::VERSION
  spec.date          = Time.now.strftime("%Y-%m-%d")

  spec.authors       = ["Adrian Setyadi"]
  spec.email         = ["a.styd@yahoo.com"]
  spec.summary       = %q{Unofficial KasPay access wrapper gem.}
  spec.description   = %q{A gem to access KasPay web using watir gem and X virtual framebuffer wrapped by headless gem.}
  spec.homepage      = "https://github.com/styd/kaspay"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  # spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  # spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]
  spec.add_runtime_dependency 'watir', '~> 5.0', '>= 5.0.0'
  spec.add_runtime_dependency 'headless', '~> 2.2', '>= 2.2.0'
end
