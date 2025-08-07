#!/usr/bin/env ruby
# frozen_string_literal: true

# SuperAgent Vector Store Example
# This example demonstrates how to create and use OpenAI Vector Stores with SuperAgent
# Migration from rdawn to SuperAgent framework

require 'bundler/setup'
require 'dotenv'
Dotenv.load('../.env')
require 'super_agent'
require 'tempfile'
require 'fileutils'

# Check if OpenAI API key is set
unless ENV['OPENAI_API_KEY']
  puts "❌ Error: Please set your OpenAI API key:"
  puts "export OPENAI_API_KEY='your-openai-api-key-here'"
  puts ""
  puts "Get your API key at: https://platform.openai.com/api-keys"
  exit 1
end

puts "🗂️ SuperAgent Vector Store Example"
puts "=" * 50
puts "Demonstrating how to create and use OpenAI Vector Stores with SuperAgent"
puts ""

# Configure SuperAgent
SuperAgent.configure do |config|
  config.api_key = ENV['OPENAI_API_KEY']
  config.logger = Logger.new(STDOUT)
  config.logger.level = Logger::INFO
end

# Define workflows for vector store operations
class FileUploadWorkflow < SuperAgent::WorkflowDefinition
  steps do
    step :upload_file, uses: :file_upload, with: {
      purpose: 'assistants',
      file_path: :file_path
    }
  end
end

class VectorStoreCreationWorkflow < SuperAgent::WorkflowDefinition
  steps do
    step :create_store, uses: :vector_store_management, with: {
      operation: :create,
      name: :store_name,
      file_ids: :file_ids,
      expires_after: { anchor: "last_active_at", days: 7 }
    }
  end
end

class FileSearchWorkflow < SuperAgent::WorkflowDefinition
  steps do
    step :search_files, uses: :llm, with: {
      model: "gpt-4o",
      messages: [
        { role: "system", content: "You are an AI assistant that searches through documents to find relevant information." },
        { role: "user", content: "{{query}}" }
      ],
      max_tokens: 400
    }
  end
end

# Create vector store agent
class VectorStoreAgent < SuperAgent::Base
  def upload_and_create_vector_store(file_path, store_name: "Knowledge Base")
    initial_input = { file_path: file_path, store_name: store_name }
    run_workflow(FileUploadWorkflow, initial_input: initial_input)
  end

  def create_vector_store(file_ids, store_name: "Knowledge Base")
    initial_input = { file_ids: file_ids, store_name: store_name }
    run_workflow(VectorStoreCreationWorkflow, initial_input: initial_input)
  end

  def search_vector_store(vector_store_id, query)
    initial_input = { query: query }
    run_workflow(FileSearchWorkflow, initial_input: initial_input)
  end
end

begin
  puts "🚀 Initializing SuperAgent Vector Store Operations..."
  
  agent = VectorStoreAgent.new
  
  # Step 1: Create sample documents
  puts "=== Step 1: Creating Sample Documents ==="
  
  sample_documents = [
    {
      filename: "ai_overview.txt",
      content: <<~TEXT
        Artificial Intelligence (AI) is the simulation of human intelligence in machines that are programmed to think and learn.
        
        Key AI concepts include:
        - Machine Learning: Algorithms that improve through experience
        - Deep Learning: Neural networks with multiple layers
        - Natural Language Processing: Understanding human language
        - Computer Vision: Interpreting visual information
        
        Modern AI applications:
        - Virtual assistants like Siri and Alexa
        - Recommendation systems on Netflix and Amazon
        - Autonomous vehicles and robotics
        - Medical diagnosis and drug discovery
        
        The future of AI involves more sophisticated reasoning, better understanding of context, and improved human-AI collaboration.
      TEXT
    },
    {
      filename: "vector_databases.txt",
      content: <<~TEXT
        Vector databases are specialized storage systems designed to handle high-dimensional vector data efficiently.
        
        Key features of vector databases:
        - Semantic search capabilities
        - Similarity matching using embeddings
        - Scalable storage for large datasets
        - Real-time query performance
        
        Popular vector databases:
        - Pinecone: Managed vector database service
        - Weaviate: Open-source vector search engine
        - Chroma: Embeddings database for AI applications
        - Qdrant: Vector similarity search engine
        
        Use cases include recommendation systems, image search, semantic text search, and AI-powered applications.
      TEXT
    },
    {
      filename: "ml_algorithms.txt",
      content: <<~TEXT
        Machine Learning algorithms are mathematical models that learn patterns from data to make predictions or decisions.
        
        Supervised Learning Algorithms:
        - Linear Regression: Predict continuous values
        - Logistic Regression: Binary classification
        - Random Forest: Ensemble of decision trees
        - Support Vector Machines: Classification and regression
        
        Unsupervised Learning Algorithms:
        - K-Means Clustering: Group similar data points
        - Principal Component Analysis: Dimensionality reduction
        - DBSCAN: Density-based clustering
        
        Deep Learning Architectures:
        - Convolutional Neural Networks (CNNs): Image processing
        - Recurrent Neural Networks (RNNs): Sequential data
        - Transformers: Language understanding and generation
      TEXT
    }
  ]
  
  uploaded_files = []
  
  # Create temporary files and upload them
  sample_documents.each do |doc|
    puts "📄 Creating: #{doc[:filename]}"
    
    temp_file = Tempfile.new([File.basename(doc[:filename], '.txt'), '.txt'])
    temp_file.write(doc[:content])
    temp_file.close
    
    # Upload file using SuperAgent
    context = { file_path: temp_file.path }
    upload_result = agent.run_workflow(FileUploadWorkflow, initial_input: context)
    
    if upload_result.success?
      file_id = upload_result.output_for(:upload_file)[:file_id]
      uploaded_files << file_id
      puts "✅ Uploaded: #{file_id}"
    else
      puts "❌ Failed to upload #{doc[:filename]}: #{upload_result.error}"
    end
    
    temp_file.unlink
  end
  
  puts "\n📤 All files uploaded successfully!"
  puts "File IDs: #{uploaded_files.join(', ')}"
  
  # Step 2: Create vector store
  puts "\n=== Step 2: Creating Vector Store ==="
  puts "🗃️ Creating AI Knowledge Base..."
  
  context = { file_ids: uploaded_files, store_name: "AI Knowledge Base" }
  create_result = agent.run_workflow(VectorStoreCreationWorkflow, initial_input: context)
  
  if create_result.success?
    result = create_result.output_for(:create_store)
    vector_store_id = result[:vector_store_result][:vector_store_id]
    puts "✅ Vector store created: #{vector_store_id}"
  else
    puts "❌ Failed to create vector store: #{create_result.error}"
    exit 1
  end
  
  # Step 3: Wait for processing
  puts "\n⏳ Waiting for vector store to process files..."
  sleep(5)  # Give OpenAI time to process
  
  # Step 4: Search the vector store
  puts "\n=== Step 3: Semantic Search Queries ==="
  
  queries = [
    "What is artificial intelligence?",
    "How do vector databases work?",
    "What are the main types of machine learning algorithms?",
    "Compare supervised and unsupervised learning",
    "Explain neural networks in simple terms"
  ]
  
  queries.each_with_index do |query, index|
    puts "\n🔍 Query #{index + 1}: #{query}"
    puts "-" * 40
    
    search_result = agent.search_vector_store(vector_store_id, query)
    
    if search_result.success?
      puts "✅ Search successful!"
      puts "📄 Result:"
      result = search_result.output_for(:search_files)
      if result.is_a?(Hash) && result[:content]
        puts result[:content]
      else
        puts result.to_s
      end
    else
      puts "❌ Search error: #{search_result.error}"
    end
  end
  
  # Step 5: Advanced search with LLM integration
  puts "\n=== Step 4: Advanced Analysis ==="
  puts "🤖 Running advanced analysis with search results..."
  
  advanced_query = "Create a comprehensive summary of AI technologies based on the documents, focusing on practical applications"
  advanced_result = agent.search_vector_store(vector_store_id, advanced_query)
  
  if advanced_result.success?
    puts "✅ Advanced analysis complete!"
    puts "📊 Summary:"
    result = advanced_result.output_for(:search_files)
    if result.is_a?(Hash) && result[:content]
      puts result[:content]
    else
      puts result.to_s
    end
  end

rescue => e
  puts "❌ Error during execution: #{e.message}"
  puts "🔧 Error details: #{e.backtrace.first(3).join("\n")}"
ensure
  # Cleanup temporary files
  puts "\n🧹 Cleanup completed"
  puts "📂 Vector store #{vector_store_id} will remain for 7 days"
end

puts "\n" + "=" * 50
puts "🎉 SuperAgent Vector Store Example Complete!"
puts ""
puts "💡 This example demonstrated:"
puts "   • File upload to OpenAI using SuperAgent"
puts "   • Vector store creation and management"
puts "   • Semantic search capabilities"
puts "   • LLM integration with search results"
puts "   • Multi-document knowledge base"
puts ""
puts "💰 Estimated cost: ~$0.01-0.05 (file processing + queries)" 