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
  spec.add_dependency 'faraday'
  spec.add_dependency 'faraday-net_http_persistent'
  spec.add_dependency 'faraday-request-timer'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/solectrus/senec'
  spec.metadata['changelog_uri'] = 'https://github.com/solectrus/senec/releases'
  spec.metadata['rubygems_mfa_required'] = 'true'

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .github appveyor Gemfile])
    end
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']
end
