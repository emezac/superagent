# frozen_string_literal: true

module SuperAgent
  # Configuration class for SuperAgent gem
  class Configuration
    attr_accessor :api_key, :default_llm_model, :logger, :tool_registry,
                  :default_llm_timeout, :default_llm_retries, :sensitive_log_filter

    def initialize
      @api_key = nil
      @default_llm_model = "gpt-4"
      @logger = default_logger
      @tool_registry = ToolRegistry.new
      @default_llm_timeout = 30
      @default_llm_retries = 3
      @sensitive_log_filter = %w[password token secret key].freeze
    end

    private

    def default_logger
      require "semantic_logger"
      SemanticLogger.default_level = :info
      SemanticLogger[SuperAgent]
    rescue LoadError
      # Fallback to standard Ruby logger if semantic_logger not available
      require "logger"
      logger = Logger.new(STDOUT)
      logger.level = Logger::INFO
      logger
    end
  end
end