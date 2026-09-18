# frozen_string_literal: true

Gem::Specification.new do |s|
  s.name        = 'rouge-lexer-caddyfile'
  s.version     = '0.2.0'
  s.summary     = 'Rouge lexer for Caddyfile'
  s.description = 'A Rouge plugin providing syntax highlighting for the Caddyfile configuration format used by the Caddy web server'
  s.authors     = ['Sean Whalen']
  s.homepage    = 'https://github.com/seanthegeek/rouge-lexer-caddyfile'
  s.license     = 'MIT'
  s.files       = Dir['lib/**/*.rb'] + Dir['spec/demos/*'] + Dir['spec/visual/samples/*'] + ['README.md']

  s.required_ruby_version = '>= 3.0'

  s.add_dependency 'rouge', '>= 3.4'

  s.metadata = {
    'source_code_uri'   => 'https://github.com/seanthegeek/rouge-lexer-caddyfile',
    'bug_tracker_uri'   => 'https://github.com/seanthegeek/rouge-lexer-caddyfile/issues',
    'changelog_uri'     => 'https://github.com/seanthegeek/rouge-lexer-caddyfile/blob/main/CHANGELOG.md',
    'documentation_uri' => 'https://github.com/seanthegeek/rouge-lexer-caddyfile/blob/main/README.md'
  }
end
