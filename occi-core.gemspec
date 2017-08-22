lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'occi/core/version'

Gem::Specification.new do |gem|
  gem.name          = 'occi-core'
  gem.version       = Occi::Core::VERSION
  gem.authors       = ['Boris Parak', 'Zdeněk Šustr']
  gem.email         = ['parak@cesnet.cz', 'sustr4@cesnet.cz']
  gem.description   = 'The rOCCI toolkit is a collection of classes simplifying implementation ' \
                      'of Open Cloud Computing Interface in Ruby'
  gem.summary       = 'The rOCCI core toolkit'
  gem.homepage      = 'https://github.com/the-rocci-project/rOCCI-core'
  gem.license       = 'Apache-2.0'

  gem.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  gem.require_paths = ['lib']

  gem.add_runtime_dependency 'json', '>= 1.8', '< 3'
  gem.add_runtime_dependency 'activesupport', '>= 4.0', '< 6'
  gem.add_runtime_dependency 'json-schema', '>= 2.5', '< 3'
  gem.add_runtime_dependency 'yell', '>= 2.0', '< 3'

  gem.add_development_dependency 'bundler', '>= 1.12', '< 2'
  gem.add_development_dependency 'rake', '>= 11.0', '< 13'
  gem.add_development_dependency 'rspec', '>= 3.4', '< 4'
  gem.add_development_dependency 'simplecov', '>= 0.11', '< 1'
  gem.add_development_dependency 'pry', '>= 0.10', '< 1'
  gem.add_development_dependency 'rubocop', '>= 0.32', '< 1'
  gem.add_development_dependency 'rubocop-rspec', '>= 1.5', '< 2'
  gem.add_development_dependency 'rubygems-tasks', '>= 0.2', '< 1'
  gem.add_development_dependency 'yard', '>= 0.8', '< 1'
  gem.add_development_dependency 'fasterer', '>= 0.3.2', '< 0.4'

  gem.required_ruby_version = '>= 2.2.2'
end
