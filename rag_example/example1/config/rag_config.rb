# config/rag_config.rb
# Configuración para entornos de producción

class RAGConfiguration
  ENVIRONMENTS = {
    development: {
      model: "gpt-4o-mini",
      max_retries: 2,
      timeout: 30,
      vector_store_ttl: 1 # 1 día
    },
    staging: {
      model: "gpt-4o-mini", 
      max_retries: 3,
      timeout: 45,
      vector_store_ttl: 7 # 7 días
    },
    production: {
      model: "gpt-4o",
      max_retries: 5,
      timeout: 60,
      vector_store_ttl: 30 # 30 días
    }
  }.freeze

  def self.for_environment(env = ENV['RAILS_ENV'] || 'development')
    ENVIRONMENTS[env.to_sym] || ENVIRONMENTS[:development]
  end

  def self.openai_client(config = nil)
    config ||= for_environment
    
    OpenAI::Client.new(
      api_key: ENV['OPENAI_API_KEY'],
      organization: ENV['OPENAI_ORGANIZATION'],
      request_timeout: config[:timeout]
    )
  end
end
