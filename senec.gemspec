require File.expand_path('lib/senec/version', __dir__)

Gem::Specification.new do |spec|
  spec.name          = 'senec'
  spec.version       = Senec::VERSION
  spec.authors       = ['Georg Ledermann']
  spec.email         = ['georg@ledermann.dev']

  spec.summary       = 'Unofficial Ruby Client for SENEC Home'
  spec.description   = 'Access your local SENEC Solar Battery Storage System'
  spec.homepage      = 'https://github.com/solectrus/senec'
  spec.license       = 'MIT'

  spec.required_ruby_version = '>= 3.2.0'

  spec.metadata = {
    'homepage_uri' => spec.homepage,
    'source_code_uri' => spec.homepage,
    'changelog_uri' => "#{spec.homepage}/releases",
    'rubygems_mfa_required' => 'true'
  }

  spec.add_dependency 'faraday'
  spec.add_dependency 'faraday-net_http_persistent'
  spec.add_dependency 'faraday-request-timer'
  spec.add_dependency 'oauth2'

  spec.files = Dir.glob('**/*', File::FNM_DOTMATCH).grep_v(
    %r{\A(?:\.git/|\.github/|bin/|test/|spec/|features/|Gemfile|\.qlty/|#{Regexp.escape(File.basename(__FILE__))})},
  ).select { |f| File.file?(f) }

  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']
end
