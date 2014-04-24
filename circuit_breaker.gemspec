# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'circuit_breaker/version'

Gem::Specification.new do |spec|
  spec.name          = "ya_circuit_breaker"
  spec.version       = CircuitBreaker::VERSION
  spec.authors       = ["Patrick Huesler"]
  spec.email         = ["patrick.huesler@gmail.com"]
  spec.summary       = %q{Basic circuit breaker in Ruby}
  spec.description   = %q{Prevent long running external calls from blocking an application}
  spec.homepage      = "https://github.com/wooga/circuit_breaker"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.5"
  spec.add_development_dependency "rake"
end
