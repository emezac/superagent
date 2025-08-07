# Sistema RAG Completo con OpenAI Vector Store y Ruby

Esta guía te muestra cómo implementar un sistema RAG (Retrieval-Augmented Generation) usando las capacidades más nuevas de OpenAI con Ruby, incluyendo el nuevo **Responses API** y **Vector Stores**.

## 🆕 Nuevas Capacidades de OpenAI (2025)

### Responses API
- **Nueva API stateful/stateless** para construir agentes AI
- **File Search integrado** como herramienta nativa
- **Filtros de metadata** para búsquedas más precisas
- **Mejor rendimiento** comparado con Assistants API

### Vector Store Mejorado
- **API oficial** (salió de beta en marzo 2025)
- **Procesamiento automático** de documentos
- **Chunking inteligente** y embeddings automáticos
- **Búsqueda híbrida** (semántica + keywords)

## 📋 Requisitos Previos

### 1. Configuración del Entorno

```bash
# Crear nuevo proyecto
mkdir mi_rag_app
cd mi_rag_app

# Inicializar Gemfile
bundle init
```

### 2. Gemfile

```ruby
# Gemfile
source 'https://rubygems.org'

gem 'openai', '~> 7.3'  # SDK oficial más reciente
gem 'dotenv', '~> 3.0'
gem 'json', '~> 2.6'

group :development do
  gem 'pry', '~> 0.14'
  gem 'rubocop', '~> 1.50'
end
```

### 3. Variables de Entorno

```bash
# .env
OPENAI_API_KEY=tu_api_key_aqui
OPENAI_ORGANIZATION=tu_org_id  # Opcional
```

### 4. Instalación

```bash
bundle install
```

## 🚀 Ejemplos de Uso Avanzados

### Configuración Básica

```ruby
require 'openai'
require 'dotenv/load'

# Inicializar cliente
client = OpenAI::Client.new(
  api_key: ENV['OPENAI_API_KEY'],
  organization: ENV['OPENAI_ORGANIZATION'] # Opcional
)
```

### Caso de Uso 1: Base de Conocimiento Empresarial

```ruby
class EnterpriseKnowledgeBase
  def initialize
    @rag = OpenAIRAGSystem.new
    @vector_store_id = setup_knowledge_base
  end

  private

  def setup_knowledge_base
    # Crear Vector Store específico
    vector_store_id = @rag.create_vector_store(
      name: "Enterprise Knowledge Base"
    )

    # Documentos empresariales típicos
    enterprise_docs = [
      "policies/hr_handbook.pdf",
      "procedures/it_protocols.md", 
      "manuals/product_documentation.pdf",
      "faqs/customer_support.txt"
    ]

    @rag.upload_files_batch(enterprise_docs)
    vector_store_id
  end

  def ask_hr_question(question)
    @rag.search_with_metadata_filter(
      question,
      metadata_filter: { "department" => "hr" }
    )
  end

  def technical_support(issue)
    @rag.search_with_responses_api(
      "Technical issue: #{issue}",
      model: "gpt-4o"  # Modelo más potente para soporte técnico
    )
  end
end
```

### Caso de Uso 2: Sistema de Documentación de API

```ruby
class APIDocumentationRAG
  def initialize(api_docs_path)
    @rag = OpenAIRAGSystem.new
    setup_api_docs(api_docs_path)
  end

  def setup_api_docs(docs_path)
    @rag.create_vector_store(name: "API Documentation")
    
    # Buscar todos los archivos de documentación
    doc_files = Dir.glob("#{docs_path}/**/*.{md,txt,json}")
    
    @rag.upload_files_batch(doc_files)
  end

  def get_endpoint_info(endpoint)
    result = @rag.search_with_responses_api(
      "Información sobre el endpoint: #{endpoint}. 
       Incluye parámetros, respuestas y ejemplos."
    )
    
    format_api_response(result)
  end

  def get_code_examples(language, functionality)
    @rag.search_with_responses_api(
      "Ejemplos de código en #{language} para #{functionality}"
    )
  end

  private

  def format_api_response(result)
    {
      answer: result[:response],
      sources: result[:files_used],
      confidence: calculate_confidence(result[:annotations])
    }
  end

  def calculate_confidence(annotations)
    # Lógica personalizada para calcular confianza
    return 0.0 if annotations.empty?
    
    # Más anotaciones = mayor confianza
    [annotations.length / 5.0, 1.0].min
  end
end
```

### Caso de Uso 3: Asistente Legal/Compliance

```ruby
class LegalComplianceRAG
  LEGAL_MODELS = {
    general: "gpt-4o-mini",
    complex: "gpt-4o",
    analysis: "gpt-4o"
  }.freeze

  def initialize
    @rag = OpenAIRAGSystem.new
    setup_legal_database
  end

  def analyze_contract(contract_text, query)
    # Subir contrato temporalmente
    temp_file = create_temp_file(contract_text)
    file_id = @rag.upload_file(temp_file.path)
    @rag.add_file_to_vector_store(file_id)

    result = @rag.search_with_responses_api(
      "Analiza el siguiente aspecto del contrato: #{query}",
      model: LEGAL_MODELS[:analysis]
    )

    # Limpiar archivo temporal
    temp_file.unlink

    result
  end

  def compliance_check(regulation, company_policy)
    @rag.search_with_metadata_filter(
      "¿Cumple la siguiente política con #{regulation}? 
       Política: #{company_policy}",
      metadata_filter: { 
        "document_type" => "regulation",
        "jurisdiction" => "mexico" 
      }
    )
  end

  private

  def setup_legal_database
    @rag.create_vector_store(name: "Legal Compliance Database")
    
    legal_docs = [
      "regulations/federal_laws.pdf",
      "regulations/industry_standards.pdf",
      "policies/company_policies.md",
      "templates/contract_templates.docx"
    ]

    @rag.upload_files_batch(legal_docs)
  end

  def create_temp_file(content)
    temp_file = Tempfile.new(['contract', '.txt'])
    temp_file.write(content)
    temp_file.rewind
    temp_file
  end
end
```

## 🔧 Configuración Avanzada

### Manejo de Errores y Retry Logic

```ruby
class RobustRAGSystem < OpenAIRAGSystem
  MAX_RETRIES = 3
  RETRY_DELAY = 2

  def search_with_retry(query, **options)
    attempt = 1
    
    begin
      search_with_responses_api(query, **options)
    rescue => error
      if attempt <= MAX_RETRIES
        puts "⚠️  Error en intento #{attempt}: #{error.message}"
        puts "🔄 Reintentando en #{RETRY_DELAY} segundos..."
        
        sleep(RETRY_DELAY * attempt)
        attempt += 1
        retry
      else
        puts "❌ Falló después de #{MAX_RETRIES} intentos"
        raise error
      end
    end
  end

  def batch_upload_with_progress(file_paths)
    total_files = file_paths.length
    
    puts "📤 Iniciando carga de #{total_files} archivos..."
    
    file_paths.each_with_index do |file_path, index|
      begin
        print "#{index + 1}/#{total_files}: #{File.basename(file_path)}... "
        
        file_id = upload_file(file_path)
        add_file_to_vector_store(file_id)
        
        puts "✅"
      rescue => error
        puts "❌ Error: #{error.message}"
      end
      
      # Pausa para evitar rate limiting
      sleep(0.5)
    end
  end
end
```

### Monitoreo y Métricas

```ruby
class RAGMetrics
  def initialize(rag_system)
    @rag = rag_system
    @query_history = []
  end

  def tracked_search(query, **options)
    start_time = Time.now
    
    result = @rag.search_with_responses_api(query, **options)
    
    end_time = Time.now
    response_time = end_time - start_time
    
    # Registrar métricas
    @query_history << {
      query: query,
      response_time: response_time,
      files_used: result[:files_used],
      timestamp: start_time,
      success: true
    }

    print_metrics(response_time, result)
    result
  rescue => error
    @query_history << {
      query: query,
      error: error.message,
      timestamp: start_time,
      success: false
    }
    raise error
  end

  def print_metrics(response_time, result)
    puts "📊 Métricas de búsqueda:"
    puts "   ⏱️  Tiempo de respuesta: #{response_time.round(2)}s"
    puts "   📄 Archivos consultados: #{result[:files_used].length}"
    puts "   💬 Longitud de respuesta: #{result[:response].length} caracteres"
  end

  def generate_report
    total_queries = @query_history.length
    successful_queries = @query_history.count { |q| q[:success] }
    
    avg_response_time = @query_history
      .select { |q| q[:success] }
      .map { |q| q[:response_time] }
      .sum / successful_queries.to_f

    puts "\n📈 Reporte de Uso:"
    puts "   Total de consultas: #{total_queries}"
    puts "   Éxito: #{successful_queries}/#{total_queries} (#{(successful_queries.to_f/total_queries*100).round(1)}%)"
    puts "   Tiempo promedio: #{avg_response_time.round(2)}s"
  end
end
```

## 💰 Costos y Optimización

### Estimación de Costos

```ruby
class CostCalculator
  PRICING = {
    vector_store_storage: 0.10,  # $0.10 per GB per day
    file_search_calls: 2.50,    # $2.50 per 1000 calls
    gpt_4o_mini_input: 0.150,   # $0.150 per 1M tokens
    gpt_4o_mini_output: 0.600,  # $0.600 per 1M tokens
    gpt_4o_input: 2.50,         # $2.50 per 1M tokens  
    gpt_4o_output: 10.00        # $10.00 per 1M tokens
  }.freeze

  def self.estimate_storage_cost(gb_size, days = 30)
    gb_size * PRICING[:vector_store_storage] * days
  end

  def self.estimate_search_cost(num_queries)
    (num_queries / 1000.0) * PRICING[:file_search_calls]
  end

  def self.daily_report(vector_store_size_gb, daily_queries)
    storage_cost = estimate_storage_cost(vector_store_size_gb, 1)
    search_cost = estimate_search_cost(daily_queries)
    
    puts "💰 Estimación de costos diarios:"
    puts "   📦 Almacenamiento (#{vector_store_size_gb}GB): $#{storage_cost.round(4)}"
    puts "   🔍 Búsquedas (#{daily_queries}): $#{search_cost.round(4)}"
    puts "   💵 Total diario: $#{(storage_cost + search_cost).round(4)}"
  end
end
```

## 🧪 Testing

```ruby
# test_rag_system.rb
require 'minitest/autorun'
require_relative 'openai_rag_system'

class TestRAGSystem < Minitest::Test
  def setup
    @rag = OpenAIRAGSystem.new
    @test_vector_store = @rag.create_vector_store(name: "Test Store")
  end

  def teardown
    @rag.cleanup
  end

  def test_vector_store_creation
    assert @rag.vector_store_id
    assert_match(/^vs_/, @rag.vector_store_id)
  end

  def test_file_upload_and_search
    # Crear archivo de prueba
    test_content = "El Ruby es un lenguaje de programación dinámico."
    File.write("test_file.txt", test_content)

    begin
      # Subir archivo
      file_id = @rag.upload_file("test_file.txt")
      @rag.add_file_to_vector_store(file_id)

      # Buscar
      result = @rag.search_with_responses_api("¿Qué es Ruby?")
      
      assert result[:response].include?("Ruby")
      assert result[:files_used].any?
    ensure
      File.delete("test_file.txt")
    end
  end
end
```

## 🔍 Casos de Uso Específicos por Industria

### E-commerce
- Base de conocimiento de productos
- FAQ automatizado
- Análisis de reseñas

### Educación  
- Material de estudio personalizado
- Respuestas automáticas a estudiantes
- Análisis de documentos académicos

### Salud
- Base de conocimiento médico
- Análisis de historiales (con privacidad)
- Protocolos y procedimientos

### Finanzas
- Análisis de regulaciones
- Reportes automáticos
- Due diligence

## 📝 Mejores Prácticas

1. **Chunking Inteligente**: Deja que OpenAI maneje el chunking automáticamente
2. **Metadata**: Usa metadata para filtros más precisos
3. **Monitoring**: Implementa logs y métricas desde el inicio
4. **Testing**: Prueba con diferentes tipos de consultas
5. **Costos**: Monitorea el uso y optimiza según necesidades

## 🚨 Consideraciones de Seguridad

- ✅ Nunca subas información sensible sin cifrado
- ✅ Implementa autenticación robusta
- ✅ Usa filtros de metadata para controlar acceso
- ✅ Monitora y auditaregularmente el uso
- ✅ Implementa rate limiting
- ✅ Valida y sanitiza todas las entradas

¡Este sistema RAG te permite aprovechar al máximo las nuevas capacidades de OpenAI con Ruby!
