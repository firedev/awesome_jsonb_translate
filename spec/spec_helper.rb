# frozen_string_literal: true

require 'awesome_jsonb_translate'
require 'active_record'
require 'i18n'
require 'logger'

# Set up locales for testing
I18n.available_locales = %i[en de]
I18n.default_locale = :en

begin
  # Set up database connection with more detailed error handling
  connection_config = {
    adapter: 'postgresql',
    database: ENV['DB_NAME'] || 'awesome_jsonb_translate_test',
    username: ENV['DB_USER'] || ENV['USER'] || 'postgres',
    password: ENV['DB_PASSWORD'] || '',
    host: ENV['DB_HOST'] || 'localhost',
    min_messages: 'warning'
  }

  # Add a logger for more helpful output
  ActiveRecord::Base.logger = Logger.new($stdout) if ENV['DB_DEBUG']
  ActiveRecord::Base.establish_connection(connection_config)

  # Test the connection
  ActiveRecord::Base.connection.execute('SELECT 1')
  puts '✓ Database connection successful' if ENV['DB_DEBUG']
rescue StandardError => e
  puts "Error connecting to database: #{e.message}"
  puts "Please ensure PostgreSQL is running and the database '#{connection_config[:database]}' exists."
  puts 'You can run bin/setup to create the test database.'
  puts ''
  puts 'Connection details attempted:'
  puts "  adapter: #{connection_config[:adapter]}"
  puts "  database: #{connection_config[:database]}"
  puts "  username: #{connection_config[:username]}"
  puts "  host: #{connection_config[:host]}"
  puts ''
  puts 'You can customize these settings with environment variables:'
  puts '  DB_NAME - database name (default: awesome_jsonb_translate_test)'
  puts '  DB_USER - database username (default: your system username or postgres)'
  puts '  DB_PASSWORD - database password (default: blank)'
  puts '  DB_HOST - database host (default: localhost)'
  puts ''
  exit(1)
end

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups
  config.filter_run_when_matching :focus
  config.example_status_persistence_file_path = 'spec/examples.txt'
  config.disable_monkey_patching!
  config.warnings = true

  config.default_formatter = 'doc' if config.files_to_run.one?

  config.profile_examples = 10
  config.order = :random
  Kernel.srand config.seed
end
