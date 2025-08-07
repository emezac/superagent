# frozen_string_literal: true

require 'bundler/setup'
require 'super_agent'
require 'openai'

# Load Capybara support for system tests
require_relative "support/capybara" if File.exist?(File.join(__dir__, "support", "capybara.rb"))

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  # Configure system tests
  config.before(:each, type: :system) do
    driven_by :rack_test
  end

  config.before(:each, type: :system, js: true) do
    driven_by :selenium_chrome_headless
  end
end