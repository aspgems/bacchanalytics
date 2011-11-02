# -*- encoding: utf-8 -*-
require File.expand_path('../lib/bacchanalytics/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["David Pérez", "Paco Guzman", "Javier Vidal", "ASPgems developers"]
  gem.email         = ["dperez@aspgems.com", "fjguzman@aspgems.com", "javier.vidal@aspgems.com", "developers@aspgems.com"]
  gem.description   = %q{Bacchanalytics is a rack middleware that inserts the Asynchronous Google Analytics
  Tracking Code in your application.}
  gem.summary       = %q{Bacchanalytics is a rack middleware that inserts the Asynchronous Google Analytics
  Tracking Code in your application.}
  gem.homepage      = "https://github.com/aspgems/bacchanalytics"

  gem.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  gem.files         = `git ls-files`.split("\n")
  gem.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  gem.name          = "bacchanalytics"
  gem.require_paths = ["lib"]
  gem.version       = Bacchanalytics::VERSION

  gem.add_runtime_dependency "rack", ">= 1.1"
  gem.add_runtime_dependency "activesupport", ">= 2"

  gem.add_development_dependency "appraisal", "~> 0.3.8"
  gem.add_development_dependency "rack-test", "~> 0.6"
  gem.add_development_dependency "nokogiri", "~> 1.5"
  gem.add_development_dependency "rake",    "~> 0.9"
end
