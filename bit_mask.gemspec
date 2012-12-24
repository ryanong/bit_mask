# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'bit_mask/version'

Gem::Specification.new do |gem|
  gem.name          = "bit_mask"
  gem.version       = BitMask::VERSION
  gem.authors       = ["Ryan Ong"]
  gem.email         = ["ryanong@gmail.com"]

  gem.description   = %q{bit_mask creates a simple api to create bit mask models. By bit masking dataing you can compress the amount of data that needs to be sent between servers and clients}
  gem.summary       = %q{bit_mask allows you to serialize/bitmask simple data sets into short compact ascii strings.}
  gem.homepage      = %q{http://github.com/ryanong/bit_hash}

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.add_development_dependency "activesupport", ">= 0"
  gem.add_development_dependency "rspec", ">= 0"
end

