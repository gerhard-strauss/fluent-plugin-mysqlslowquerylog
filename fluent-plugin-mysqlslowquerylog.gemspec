# -*- encoding: utf-8 -*-

Gem::Specification.new do |gem|
  gem.name          = "fluent-plugin-mysqlslowquerylog-ippen-digital"
  gem.version       = "0.0.4"
  gem.authors       = ["Satoshi SUZUKI", "Gerhard Strauss"]
  gem.email         = ["studio3104.com@gmail.com", "gerhard.strauss@ippen-digital.de"]
  gem.description   = %q{Fluentd plugin to concat MySQL slowquerylog.}
  gem.summary       = %q{Fluentd plugin to concat MySQL slowquerylog.}
  gem.homepage      = "https://github.com/gerhard-strauss/fluent-plugin-mysqlslowquerylog"

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.add_development_dependency "fluentd"
  gem.add_runtime_dependency "fluentd"
end
