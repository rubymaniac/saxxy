# -*- encoding: utf-8 -*-
require File.expand_path('../lib/saxxy/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["rubymaniac"]
  gem.description   = %q{A Ruby DSL for building SAX parsers.}
  gem.summary       = %q{Constructing SAX parsers never been easier.}
  gem.homepage      = "https://github.com/rubymaniac/saxxy"

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "saxxy"
  gem.require_paths = ["lib"]
  gem.version       = Saxxy::VERSION

  gem.add_development_dependency "rake"
  gem.add_development_dependency "rspec", "~> 2.11"
  gem.add_development_dependency "fakeweb"
  gem.add_development_dependency "pry"
end
