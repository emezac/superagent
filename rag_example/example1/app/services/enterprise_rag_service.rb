# app/services/enterprise_rag_service.rb
# Servicio empresarial con todas las características

class EnterpriseRAGService < ProductionRAGSystem
  attr_reader :vector_stores

  def initialize(environment: nil)
    super(environment)
    @vector_stores = {}
    load_vector_stores
  end

  # Gestión de múltiples vector stores por departamento/categoría
  def create_department_store(department, documents = [])
    store_name = "#{department}_knowledge_base"
    
    @logger.info("Creating vector store", { department: department, documents: documents.length })
    
    vector_store = @client.vector_stores.create(
      parameters: {
        name: store_name,
        expires_after: {
          anchor: "last_active_at",
          days: @config[:vector_store_ttl]
        },
        metadata: {
          department: department,
          created_at: Time.now.iso8601,
          document_count: documents.length
        }
      }
    )

    @vector_stores[department] = {
      id: vector_store["id"],
      name: store_name,
      created_at: Time.now,
      document_count: 0
    }

    if documents.any?
      upload_documents_to_store(department, documents)
    end

    vector_store["id"]
  end

  # Búsqueda específica por departamento
  def departmental_search(department, query, **options)
    store_info = @vector_stores[department]
    raise "Vector store not found for department: #{department}" unless store_info

    @client.responses.create(
      parameters: {
        input: query,
        model: @config[:model],
        tools: [
          {
            type: "file_search",
            vector_store_ids: [store_info[:id]]
          }
        ],
        **options
      }
    )
  end

  # Búsqueda cross-departamental
  def cross_departmental_search(departments, query, **options)
    store_ids = departments.map { |dept| @vector_stores.dig(dept, :id) }.compact
    raise "No valid vector stores found" if store_ids.empty?

    @client.responses.create(
      parameters: {
        input: query,
        model: @config[:model],
        tools: [
          {
            type: "file_search", 
            vector_store_ids: store_ids
          }
        ],
        **options
      }
    )
  end

  # Análisis de uso y métricas
  def generate_usage_report(days = 30)
    end_date = Date.today
    start_date = end_date - days

    report = {
      period: "#{start_date} to #{end_date}",
      vector_stores: @vector_stores.length,
      total_documents: @vector_stores.values.sum { |vs| vs[:document_count] },
      departments: @vector_stores.keys,
      estimated_costs: calculate_costs(days)
    }

    @logger.info("Usage Report Generated", report)
    report
  end

  # Backup de configuración
  def backup_configuration
    config = {
      vector_stores: @vector_stores,
      environment: ENV['RAILS_ENV'],
      backup_timestamp: Time.now.iso8601,
      version: "1.0"
    }

    backup_path = "backups/rag_config_#{Time.now.strftime('%Y%m%d_%H%M%S')}.json"
    FileUtils.mkdir_p(File.dirname(backup_path))
    File.write(backup_path, JSON.pretty_generate(config))
    
    @logger.info("Configuration backed up", { path: backup_path })
    backup_path
  end

  # Restaurar desde backup
  def restore_from_backup(backup_path)
    unless File.exist?(backup_path)
      raise "Backup file not found: #{backup_path}"
    end

    config = JSON.parse(File.read(backup_path))
    @vector_stores = config["vector_stores"]
    
    @logger.info("Configuration restored", { 
      backup_timestamp: config["backup_timestamp"],
      vector_stores: @vector_stores.length 
    })
  end

  # Limpieza automática de stores expirados
  def cleanup_expired_stores
    expired_stores = []

    @vector_stores.each do |department, store_info|
      days_old = (Time.now - store_info[:created_at]) / 1.day
      
      if days_old > @config[:vector_store_ttl]
        begin
          @client.vector_stores.delete(id: store_info[:id])
          expired_stores << department
          @logger.info("Deleted expired vector store", { 
            department: department, 
            days_old: days_old.round(1) 
          })
        rescue => error
          @logger.error("Failed to delete vector store", { 
            department: department, 
            error: error.message 
          })
        end
      end
    end

    expired_stores.each { |dept| @vector_stores.delete(dept) }
    expired_stores
  end

  private

  def load_vector_stores
    # Cargar configuración existente desde archivo o base de datos
    config_path = "config/vector_stores.json"
    
    if File.exist?(config_path)
      @vector_stores = JSON.parse(File.read(config_path))
      @logger.info("Loaded existing vector stores", { count: @vector_stores.length })
    end
  end

  def upload_documents_to_store(department, documents)
    store_info = @vector_stores[department]
    existing_files = documents.select { |doc| File.exist?(doc) }
    
    if existing_files.any?
      file_streams = existing_files.map { |path| File.open(path, "rb") }
      
      begin
        file_batch = @client.vector_stores.file_batches.upload_and_poll(
          vector_store_id: store_info[:id],
          files: file_streams
        )

        @vector_stores[department][:document_count] = file_batch["file_counts"]["completed"]
        
        @logger.info("Documents uploaded", {
          department: department,
          total: file_batch["file_counts"]["total"],
          completed: file_batch["file_counts"]["completed"],
          failed: file_batch["file_counts"]["failed"]
        })
      ensure
        file_streams.each(&:close)
      end
    end
  end

  def calculate_costs(days)
    total_storage_gb = @vector_stores.values.sum do |store_info|
      # Estimación basada en número de documentos
      store_info[:document_count] * 0.01 # 10MB promedio por documento
    end

    storage_cost = total_storage_gb * 0.10 * days # $0.10 per GB per day
    
    {
      storage_gb: total_storage_gb.round(2),
      storage_cost_usd: storage_cost.round(4),
      period_days: days
    }
  end
end
