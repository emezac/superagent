# frozen_string_literal: true

require "zeitwerk"
require "dry/struct"
require "dry/types"
require "active_job"
require "active_support"

# Zeitwerk setup for automatic loading
loader = Zeitwerk::Loader.for_gem
loader.ignore("#{__dir__}/generators")
loader.setup

module SuperAgent
  class Error < StandardError; end
  class ConfigurationError < Error; end
  class WorkflowError < Error; end
  class TaskError < Error; end

  # Main configuration method for the gem
  def self.configure
    yield(configuration)
  end

  # Access the global configuration
  def self.configuration
    @configuration ||= Configuration.new
  end

  # Reset configuration (mainly for testing)
  def self.reset_configuration
    @configuration = nil
  end
end

require_relative "super_agent/step_result"

# Conditionally load Rails-specific components
if defined?(Rails)
  require_relative "super_agent/execution_model"
end
