# frozen_string_literal: true

require_relative 'lib/awesome_jsonb_translate/version'

Gem::Specification.new do |spec|
  spec.name          = 'awesome_jsonb_translate'
  spec.version       = AwesomeJsonbTranslate::VERSION
  spec.authors       = ['Your Name']
  spec.email         = ['your.email@example.com']

  spec.summary       = "ActiveRecord translations using PostgreSQL's JSONB data type"
  spec.description   = "This gem uses PostgreSQL's JSONB datatype to store and retrieve translations for ActiveRecord models without extra columns or tables"
  spec.homepage      = 'https://github.com/username/awesome_jsonb_translate'
  spec.license       = 'MIT'
  spec.required_ruby_version = '>= 2.6.0'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = spec.homepage
  spec.metadata['changelog_uri'] = "#{spec.homepage}/blob/main/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  spec.files = Dir['{lib}/**/*', 'LICENSE.txt', 'README.md']

  spec.require_paths = ['lib']

  spec.add_dependency 'activerecord', '>= 5.0'
  spec.add_dependency 'i18n', '>= 0.7'

  spec.add_development_dependency 'pg', '~> 1.0'
  spec.add_development_dependency 'rake', '~> 13.0'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.metadata['rubygems_mfa_required'] = 'true'
end
