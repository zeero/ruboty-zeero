# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'ruboty/zeero/version'

Gem::Specification.new do |spec|
  spec.name          = "ruboty-zeero"
  spec.version       = Ruboty::Zeero::VERSION
  spec.authors       = ["zeero"]
  spec.email         = ["zeero26@gmail.com"]
  spec.date          = "2016-12-17"

  spec.summary       = %q{My Ruboty.}
  spec.homepage      = "https://github.com/zeero/ruboty-zeero"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "chrono"
  spec.add_dependency "qiita"
  spec.add_runtime_dependency "ruboty"
  spec.add_development_dependency "bundler", "~> 1.13"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "pry"
  spec.add_development_dependency "minitest", "~> 5.0"
  spec.add_development_dependency "minitest-doc_reporter"
  spec.add_development_dependency "minitest-stub_any_instance"
end
