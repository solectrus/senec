require_relative 'lib/senec/version'

Gem::Specification.new do |spec|
  spec.name          = 'senec'
  spec.version       = Senec::VERSION
  spec.authors       = ['Georg Ledermann']
  spec.email         = ['georg@ledermann.dev']

  spec.summary       = 'Unofficial Ruby Client for SENEC Home'
  spec.description   = 'Access your local SENEC Solar Battery Storage System'
  spec.homepage      = 'https://github.com/solectrus/senec'
  spec.license       = 'MIT'
  spec.required_ruby_version = Gem::Requirement.new('>= 3.2.0')
  spec.add_runtime_dependency 'faraday'
  spec.add_runtime_dependency 'faraday-net_http_persistent'
  spec.add_runtime_dependency 'faraday-request-timer'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/solectrus/senec'
  spec.metadata['changelog_uri'] = 'https://github.com/solectrus/senec/releases'
  spec.metadata['rubygems_mfa_required'] = 'true'

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files =
    Dir.chdir(File.expand_path(__dir__)) do
      `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
    end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']
end
