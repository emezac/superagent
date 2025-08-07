# frozen_string_literal: true

SuperAgent.configure do |config|
  # OpenAI Configuration
  config.openai_api_key = ENV['OPENAI_API_KEY']
  config.openai_organization_id = ENV['OPENAI_ORGANIZATION_ID']
  
  # Anthropic Configuration  
  config.anthropic_api_key = ENV['ANTHROPIC_API_KEY']
  
  # Default LLM settings
  config.default_llm_model = "gpt-4"
  config.default_llm_timeout = 30
  config.default_llm_retries = 2
  
  # Logging configuration
  config.logger = Rails.logger
  config.log_level = :info
  
  # Security settings
  config.sensitive_log_filter = [
    :password, :token, :secret, :key, /password/i, /token/i, /secret/i
  ]
  
  # Background job settings
  config.async_queue = :default
  
  # Redis configuration (for background jobs)
  # config.redis_url = ENV['REDIS_URL'] || 'redis://localhost:6379/0'
end
EOF < /dev/null