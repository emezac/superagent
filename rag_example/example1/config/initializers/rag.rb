# config/initializers/rag.rb (Para Rails)
if defined?(Rails)
  Rails.application.configure do
    config.rag_service = EnterpriseRAGService.new(
      environment: Rails.env
    )
  end
end
