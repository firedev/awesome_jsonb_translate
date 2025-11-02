# frozen_string_literal: true

require_relative 'lib/awesome_jsonb_translate/version'

Gem::Specification.new do |spec|
  spec.name          = 'awesome_jsonb_translate'
  spec.version       = AwesomeJsonbTranslate::VERSION
  spec.authors       = ['Nick Ostrovsky']
  spec.email         = ['nick@firedev.com']

  spec.summary       = "ActiveRecord translations using PostgreSQL's JSONB data type"
  spec.description   = "This gem uses PostgreSQL's JSONB datatype to store and retrieve translations " \
                       'for ActiveRecord models without extra columns or tables'
  spec.homepage      = 'https://github.com/firedev/awesome_jsonb_translate'
  spec.license       = 'MIT'
  spec.required_ruby_version = '>= 2.7.0'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = "#{spec.homepage}/tree/master"
  spec.metadata['documentation_uri'] = "#{spec.homepage}/blob/master/README.md"
  spec.metadata['changelog_uri'] = "#{spec.homepage}/blob/master/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  spec.files = Dir['{lib}/**/*', 'LICENSE.txt', 'README.md']

  spec.require_paths = ['lib']

  spec.add_dependency 'activerecord'
  spec.add_dependency 'i18n'

  spec.metadata['rubygems_mfa_required'] = 'true'
end
