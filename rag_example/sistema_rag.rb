
require 'openai'
require 'dotenv/load'
require 'json'
require 'pathname'
require 'net/http'
require 'uri'

class OpenAIRAGSystemSimplified
  def initialize
    @client = OpenAI::Client.new(
      api_key: ENV['OPENAI_API_KEY']
    )
    @api_key = ENV['OPENAI_API_KEY']
    @vector_store_id = nil
  end

  # 1. Crear Vector Store usando API REST directa (workaround)
  def create_vector_store(name: "RAG Knowledge Base")
    puts "🔧 Creando Vector Store: #{name} (via REST API)"
    
    uri = URI('https://api.openai.com/v1/vector_stores')
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    
    request = Net::HTTP::Post.new(uri)
    request['Authorization'] = "Bearer #{@api_key}"
    request['Content-Type'] = 'application/json'
    request['OpenAI-Beta'] = 'assistants=v2'
    
    request.body = {
      name: name,
      expires_after: {
        anchor: "last_active_at",
        days: 7
      }
    }.to_json
    
    response = http.request(request)
    
    if response.code == '200'
      result = JSON.parse(response.body)
      @vector_store_id = result['id']
      puts "✅ Vector Store creado: #{@vector_store_id}"
      return @vector_store_id
    else
      puts "❌ Error creando Vector Store: #{response.body}"
      return nil
    end
  end

  # 2. Subir archivos individuales (SDK Oficial funciona)
  def upload_file(file_path, purpose: "assistants")
    puts "📤 Subiendo archivo: #{File.basename(file_path)}"
    
    file_object = @client.files.create(
      file: Pathname.new(file_path),
      purpose: purpose
    )
    
    puts "✅ Archivo subido: #{file_object.id}"
    return file_object.id
  end

  # 3. Agregar archivos al Vector Store (via REST API)
  def add_file_to_vector_store(file_id)
    raise "Vector Store no ha sido creado" unless @vector_store_id
    
    puts "🔗 Agregando archivo al Vector Store..."
    
    uri = URI("https://api.openai.com/v1/vector_stores/#{@vector_store_id}/files")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    
    request = Net::HTTP::Post.new(uri)
    request['Authorization'] = "Bearer #{@api_key}"
    request['Content-Type'] = 'application/json'
    request['OpenAI-Beta'] = 'assistants=v2'
    
    request.body = { file_id: file_id }.to_json
    
    response = http.request(request)
    
    if response.code == '200'
      result = JSON.parse(response.body)
      puts "✅ Archivo agregado al Vector Store: #{result['id']}"
      return result['id']
    else
      puts "❌ Error agregando archivo: #{response.body}"
      return nil
    end
  end

  # 4. Subir múltiples archivos secuencialmente
  def upload_files_batch(file_paths)
    raise "Vector Store no ha sido creado" unless @vector_store_id
    
    puts "📤 Subiendo #{file_paths.length} archivos secuencialmente..."
    
    completed = 0
    failed = 0
    
    file_paths.each do |file_path|
      begin
        file_id = upload_file(file_path)
        if add_file_to_vector_store(file_id)
          completed += 1
        else
          failed += 1
        end
        sleep(1) # Evitar rate limiting
      rescue => e
        puts "❌ Error con #{file_path}: #{e.message}"
        failed += 1
      end
    end
    
    puts "✅ Archivos procesados:"
    puts "   Completados: #{completed}"
    puts "   Fallidos: #{failed}"
    
    return { completed: completed, failed: failed }
  end

  # 5. Verificar el estado del Vector Store (via REST API)
  def check_vector_store_status
    raise "Vector Store no ha sido creado" unless @vector_store_id
    
    uri = URI("https://api.openai.com/v1/vector_stores/#{@vector_store_id}")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    
    request = Net::HTTP::Get.new(uri)
    request['Authorization'] = "Bearer #{@api_key}"
    request['OpenAI-Beta'] = 'assistants=v2'
    
    response = http.request(request)
    
    if response.code == '200'
      result = JSON.parse(response.body)
      
      puts "📊 Estado del Vector Store:"
      puts "   ID: #{result['id']}"
      puts "   Name: #{result['name']}"
      puts "   Status: #{result['status']}"
      puts "   File counts: #{result['file_counts']['total'] || 0}"
      puts "   Usage bytes: #{result['usage_bytes'] || 0}"
      
      return result
    else
      puts "❌ Error verificando estado: #{response.body}"
      return nil
    end
  end

  # 6. Crear Assistant con File Search (SDK Oficial funciona)
  def create_assistant_with_search(name: "RAG Assistant", instructions: nil)
    raise "Vector Store no ha sido creado" unless @vector_store_id
    
    default_instructions = "Eres un asistente experto que responde preguntas basándose en los documentos proporcionados. Siempre cita las fuentes cuando sea posible."
    
    begin
      # Intentar con SDK oficial si tiene soporte para assistants
      assistant = @client.beta.assistants.create(
        name: name,
        instructions: instructions || default_instructions,
        model: "gpt-4o-mini",
        tools: [{ type: "file_search" }],
        tool_resources: {
          file_search: {
            vector_store_ids: [@vector_store_id]
          }
        }
      )
      
      puts "🤖 Assistant creado: #{assistant.id}"
      return assistant.id
    rescue NoMethodError => e
      puts "⚠️  SDK oficial no soporta assistants, usando REST API..."
      return create_assistant_via_rest(name, instructions)
    end
  end

  # 6b. Crear Assistant via REST API (fallback)
  def create_assistant_via_rest(name, instructions)
    default_instructions = "Eres un asistente experto que responde preguntas basándose en los documentos proporcionados."
    
    uri = URI('https://api.openai.com/v1/assistants')
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    
    request = Net::HTTP::Post.new(uri)
    request['Authorization'] = "Bearer #{@api_key}"
    request['Content-Type'] = 'application/json'
    request['OpenAI-Beta'] = 'assistants=v2'
    
    request.body = {
      name: name,
      instructions: instructions || default_instructions,
      model: "gpt-4o-mini",
      tools: [{ type: "file_search" }],
      tool_resources: {
        file_search: {
          vector_store_ids: [@vector_store_id]
        }
      }
    }.to_json
    
    response = http.request(request)
    
    if response.code == '200'
      result = JSON.parse(response.body)
      puts "🤖 Assistant creado via REST: #{result['id']}"
      return result['id']
    else
      puts "❌ Error creando assistant: #{response.body}"
      return nil
    end
  end

  # 7. Búsqueda usando Chat Completions API básica (sin Assistants)
  def search_with_chat_api(query, context_files: [])
    puts "🔍 Búsqueda básica con Chat API: '#{query}'"
    
    # Leer contenido de archivos como contexto
    context = ""
    context_files.each do |file_path|
      if File.exist?(file_path)
        content = File.read(file_path)[0..4000] # Limitar tamaño
        context += "=== #{File.basename(file_path)} ===\n#{content}\n\n"
      end
    end
    
    messages = [
      {
        role: "system",
        content: "Eres un asistente que responde preguntas basándose en los documentos proporcionados. Cita las fuentes cuando sea posible."
      },
      {
        role: "user", 
        content: "Contexto:\n#{context}\n\nPregunta: #{query}"
      }
    ]
    
    response = @client.chat.completions.create(
      model: "gpt-4o-mini",
      messages: messages,
      max_tokens: 1000
    )
    
    result = response.choices.first.message.content
    
    puts "✅ Búsqueda completada (Chat API)"
    
    return {
      response: result,
      method: "chat_api",
      files_used: context_files.map { |f| File.basename(f) }
    }
  end

  # 8. Búsqueda híbrida (intenta Assistants, fallback a Chat API)
  def search_with_hybrid_approach(query, assistant_id: nil, context_files: [])
    if assistant_id
      begin
        return search_with_assistants_api(query, assistant_id: assistant_id)
      rescue => e
        puts "⚠️  Error con Assistants API: #{e.message}"
        puts "🔄 Intentando con Chat API básica..."
        return search_with_chat_api(query, context_files: context_files)
      end
    else
      return search_with_chat_api(query, context_files: context_files)
    end
  end

  # 7 alternativo. Búsqueda usando Assistants API (si disponible)
  def search_with_assistants_api(query, assistant_id:)
    puts "🔍 Búsqueda con Assistants API: '#{query}'"
    
    begin
      # Intentar con SDK oficial
      thread = @client.beta.threads.create
      
      @client.beta.threads.messages.create(
        thread_id: thread.id,
        role: "user",
        content: query
      )
      
      run = @client.beta.threads.runs.create_and_poll(
        thread_id: thread.id,
        assistant_id: assistant_id
      )
      
      messages = @client.beta.threads.messages.list(
        thread_id: thread.id,
        order: "desc",
        limit: 1
      )
      
      response_message = messages.data.first
      
      puts "✅ Búsqueda completada (Assistants API)"
      
      return {
        response: response_message.content.first.text.value,
        annotations: response_message.content.first.text.annotations || [],
        assistant_id: assistant_id,
        thread_id: thread.id,
        method: "assistants_api"
      }
    rescue NoMethodError => e
      puts "⚠️  SDK no soporta Assistants API completa: #{e.message}"
      raise e
    end
  end

  # 9. Listar archivos del Vector Store (via REST API)
  def list_vector_store_files
    raise "Vector Store no ha sido creado" unless @vector_store_id
    
    uri = URI("https://api.openai.com/v1/vector_stores/#{@vector_store_id}/files")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    
    request = Net::HTTP::Get.new(uri)
    request['Authorization'] = "Bearer #{@api_key}"
    request['OpenAI-Beta'] = 'assistants=v2'
    
    response = http.request(request)
    
    if response.code == '200'
      result = JSON.parse(response.body)
      files_info = result['data'].map do |file|
        {
          id: file['id'],
          usage_bytes: file['usage_bytes'] || 0,
          created_at: Time.at(file['created_at']),
          status: file['status']
        }
      end
      
      puts "📁 Archivos en el Vector Store:"
      files_info.each_with_index do |file, index|
        puts "   #{index + 1}. ID: #{file[:id]}"
        puts "      Status: #{file[:status]}"
        puts "      Size: #{file[:usage_bytes]} bytes"
        puts "      Created: #{file[:created_at]}"
      end
      
      return files_info
    else
      puts "❌ Error listando archivos: #{response.body}"
      return []
    end
  end

  # 10. Limpiar recursos (via REST API)
  def cleanup
    if @vector_store_id
      puts "🗑️  Eliminando Vector Store..."
      
      uri = URI("https://api.openai.com/v1/vector_stores/#{@vector_store_id}")
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      
      request = Net::HTTP::Delete.new(uri)
      request['Authorization'] = "Bearer #{@api_key}"
      request['OpenAI-Beta'] = 'assistants=v2'
      
      response = http.request(request)
      
      if response.code == '200'
        puts "✅ Vector Store eliminado"
      else
        puts "⚠️  Error eliminando Vector Store: #{response.body}"
      end
      
      @vector_store_id = nil
    end
  end

# Cambiar nombre de clase para evitar confusión
class OpenAIRAGSystemSimplified
  # ... resto del código ya actualizado

  # Método auxiliar para obtener el Vector Store ID
  attr_reader :vector_store_id
end

# Ejemplo de uso corregido para SDK Oficial con limitaciones
class RAGDemoSimplified
  def self.run
    # Inicializar el sistema RAG simplificado
    rag = OpenAIRAGSystemSimplified.new
    
    begin
      # 1. Crear Vector Store
      vector_store_id = rag.create_vector_store(name: "Demo Knowledge Base")
      
      unless vector_store_id
        puts "❌ No se pudo crear Vector Store, usando modo básico"
        return run_basic_mode
      end
      
      # 2. Definir archivos para subir
      file_paths = [
        "documents/manual.pdf",
        "documents/faq.txt", 
        "documents/technical_specs.md"
      ]
      
      # Verificar archivos existentes
      existing_files = file_paths.select { |path| File.exist?(path) }
      
      if existing_files.empty?
        puts "⚠️  No se encontraron archivos. Creando archivos de ejemplo..."
        create_sample_files
        existing_files = ["sample_document.txt"]
      end
      
      # 3. Subir archivos
      result = rag.upload_files_batch(existing_files)
      
      if result[:completed] == 0
        puts "⚠️  No se pudieron subir archivos, usando modo básico con archivos locales"
        return run_basic_mode(existing_files)
      end
      
      # 4. Verificar estado
      rag.check_vector_store_status
      
      # 5. Esperar procesamiento
      puts "⏱️  Esperando procesamiento de archivos..."
      sleep(5)
      
      # 6. Intentar crear assistant
      assistant_id = rag.create_assistant_with_search
      
      # 7. Realizar búsquedas
      puts "\n" + "="*50
      puts "REALIZANDO BÚSQUEDAS RAG"
      puts "="*50
      
      queries = [
        "¿Cuáles son las características principales?",
        "¿Cómo puedo resolver problemas comunes?", 
        "¿Qué especificaciones técnicas son importantes?"
      ]
      
      queries.each_with_index do |query, index|
        puts "\n#{index + 1}. Búsqueda:"
        
        begin
          result = rag.search_with_hybrid_approach(
            query, 
            assistant_id: assistant_id,
            context_files: existing_files
          )
          
          puts "   Método usado: #{result[:method]}"
          puts "   Respuesta: #{result[:response][0..200]}..."
          puts "   Archivos: #{result[:files_used]&.join(', ')}"
        rescue => e
          puts "   ❌ Error en búsqueda: #{e.message}"
        end
        
        sleep(2) # Evitar rate limiting
      end
      
    rescue => e
      puts "❌ Error general: #{e.message}"
      puts "🔄 Intentando modo básico..."
      return run_basic_mode(["sample_document.txt"])
    ensure
      # Limpiar recursos
      puts "\n" + "="*30
      puts "LIMPIEZA"
      puts "="*30
      rag.cleanup if rag.respond_to?(:cleanup)
    end
  end
  
  # Modo básico sin Vector Stores (solo Chat API)
  def self.run_basic_mode(files = [])
    puts "\n🔄 EJECUTANDO EN MODO BÁSICO (Sin Vector Stores)"
    puts "="*50
    
    if files.empty?
      create_sample_files
      files = ["sample_document.txt"]
    end
    
    rag = OpenAIRAGSystemSimplified.new
    
    queries = [
      "¿Cuáles son las características principales?",
      "¿Cómo puedo resolver problemas comunes?",
      "¿Qué especificaciones técnicas son importantes?"
    ]
    
    queries.each_with_index do |query, index|
      puts "\n#{index + 1}. Búsqueda básica:"
      
      begin
        result = rag.search_with_chat_api(query, context_files: files)
        puts "   Respuesta: #{result[:response][0..200]}..."
        puts "   Archivos: #{result[:files_used].join(', ')}"
      rescue => e
        puts "   ❌ Error: #{e.message}"
      end
      
      sleep(1)
    end
  end_with_assistants_api(query, assistant_id: assistant_id)
        puts "   Respuesta: #{result[:response][0..200]}..."
        puts "   Anotaciones: #{result[:annotations].length}"
        
        sleep(2) # Evitar rate limiting
      end
      
    rescue => e
      puts "❌ Error: #{e.message}"
      puts e.backtrace.first(5)
    ensure
      # Limpiar recursos
      puts "\n" + "="*30
      puts "LIMPIEZA"
      puts "="*30
      rag.cleanup
    end
  end
  
  private
  
  def self.create_sample_files
    content = <<~TEXT
      # Documento de Ejemplo para RAG
      
      Este es un documento de ejemplo para demostrar las capacidades RAG de OpenAI.
      
      ## Características Principales
      - Búsqueda semántica avanzada usando Vector Stores
      - Integración con Assistants API de OpenAI
      - Soporte para múltiples formatos de archivo (PDF, TXT, MD, DOC)
      - API fácil de usar con Ruby
      - Procesamiento automático de documentos
      
      ## Especificaciones Técnicas
      - Modelo: GPT-4o-mini para consultas eficientes
      - Embeddings: Generados automáticamente por OpenAI
      - Capacidad: Hasta 10,000 archivos por Vector Store
      - Formatos soportados: PDF, TXT, MD, DOC, DOCX, etc.
      - Chunking: Automático y optimizado
      
      ## Preguntas Frecuentes
      
      ### ¿Cómo resolver problemas comunes?
      1. Verificar que los archivos se hayan procesado correctamente
      2. Revisar el estado del Vector Store con check_vector_store_status
      3. Asegurar que las consultas sean específicas y claras
      4. Esperar unos segundos después de subir archivos para que se procesen
      
      ### ¿Qué beneficios ofrece RAG?
      - Respuestas basadas en documentos propios y actualizados
      - Reducción significativa de alucinaciones del modelo
      - Contexto relevante y específico para cada consulta
      - Citas automáticas de fuentes cuando es posible
      - Escalabilidad para grandes bases de conocimiento
      
      ### ¿Cómo optimizar el rendimiento?
      - Usar archivos bien estructurados y con contenido claro
      - Dividir documentos muy largos en secciones más pequeñas
      - Usar nombres de archivo descriptivos
      - Implementar cache para consultas frecuentes
      - Monitorear el uso y costos regularmente
    TEXT
    
    File.write("sample_document.txt", content)
    puts "✅ Archivo de ejemplo creado: sample_document.txt"
  end
end

# Clase adicional para manejo de múltiples Vector Stores (SDK Oficial)
class EnterpriseRAGSystem < OpenAIRAGSystem
  def initialize
    super
    @vector_stores = {}
  end

  def create_department_vector_store(department, documents = [])
    store_name = "#{department}_knowledge_base"
    
    puts "🏢 Creando Vector Store para departamento: #{department}"
    
    vector_store = @client.beta.vector_stores.create(
      name: store_name,
      expires_after: {
        anchor: "last_active_at", 
        days: 30
      }
    )

    @vector_stores[department] = {
      id: vector_store.id,
      name: store_name,
      created_at: Time.now
    }

    if documents.any?
      upload_documents_to_department(department, documents)
    end

    vector_store.id
  end

  def search_by_department(department, query)
    store_info = @vector_stores[department]
    raise "Vector store not found for department: #{department}" unless store_info

    # Usar el Vector Store específico del departamento
    old_store_id = @vector_store_id
    @vector_store_id = store_info[:id]
    
    begin
      search_with_assistants_api(query)
    ensure
      @vector_store_id = old_store_id
    end
  end

  def list_all_departments
    @vector_stores.keys
  end

  def cleanup_department(department)
    store_info = @vector_stores[department]
    return false unless store_info

    @client.beta.vector_stores.delete(id: store_info[:id])
    @vector_stores.delete(department)
    puts "✅ Vector Store eliminado para departamento: #{department}"
    true
  end

  private

  def upload_documents_to_department(department, documents)
    store_info = @vector_stores[department]
    existing_files = documents.select { |doc| File.exist?(doc) }
    
    if existing_files.any?
      file_streams = existing_files.map { |path| File.open(path, "rb") }
      
      begin
        @client.beta.vector_stores.file_batches.upload_and_poll(
          vector_store_id: store_info[:id],
          files: file_streams
        )
        puts "📁 Documentos subidos para #{department}: #{existing_files.length} archivos"
      ensure
        file_streams.each(&:close)
      end
    end
  end
end

# Ejecutar la demostración
if __FILE__ == $0
  puts "🚀 Iniciando demostración del Sistema RAG con OpenAI (SDK Oficial)"
  puts "="*60
  
  # Verificar que la API key esté configurada
  unless ENV['OPENAI_API_KEY']
    puts "❌ Error: OPENAI_API_KEY no está configurada"
    puts "   Configura tu API key: export OPENAI_API_KEY='tu-api-key'"
    exit 1
  end
  
  # Verificar que estemos usando el SDK correcto
  puts "📦 Usando SDK: openai gem v#{OpenAI::VERSION}" rescue puts "📦 Usando SDK: openai gem"
  
  RAGDemo.run
  
  puts "\n🎉 Demostración completada!"
end
