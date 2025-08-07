# SuperAgent Examples - Real OpenAI API Integration

This directory contains comprehensive examples demonstrating SuperAgent's capabilities with real OpenAI API calls. These examples migrate from the older `rdawn` framework to the new SuperAgent architecture.

## 📋 Examples Overview

| Example | Description | Key Features | Estimated Cost |
|---------|-------------|--------------|----------------|
| [01_simple_llm_example.rb](01_simple_llm_example.rb) | Basic LLM integration | GPT-4o-mini, simple prompts | $0.01-0.05 |
| [02_web_search_example.rb](02_web_search_example.rb) | Real-time web search | GPT-4o with web search capability | $0.05-0.15 |
| [03_vector_store_example.rb](03_vector_store_example.rb) | Document indexing & search | Vector stores, semantic search | $0.01-0.05 |
| [04_legal_pdf_analysis.rb](04_legal_pdf_analysis.rb) | Legal document analysis | PDF processing, multi-stage analysis | $0.10-0.50 |
| [05_image_generation_example.rb](05_image_generation_example.rb) | Image generation | DALL-E 3, multiple styles | $0.10-0.50 |

## 🚀 Getting Started

### 1. Setup Environment

```bash
# Run the setup script
./setup_examples.sh

# Or manually:
export OPENAI_API_KEY='your-openai-api-key-here'
bundle install
```

### 2. Verify Installation

```bash
# Test basic functionality
ruby 01_simple_llm_example.rb
```

### 3. Run Individual Examples

```bash
# Basic LLM interaction
ruby 01_simple_llm_example.rb

# Web search capabilities  
ruby 02_web_search_example.rb

# Document processing
ruby 03_vector_store_example.rb

# Legal analysis (requires samplerenting.pdf)
ruby 04_legal_pdf_analysis.rb

# Image generation
ruby 05_image_generation_example.rb
```

## 🔧 Configuration

### Environment Variables

```bash
# Required
export OPENAI_API_KEY='your-key-here'

# Optional: Logging level
export SUPERAGENT_LOG_LEVEL='info'
```

### Output Directories

- `../outputs/images/` - Generated images
- `../outputs/reports/` - Analysis reports
- `../outputs/` - Other generated files

## 📚 Example Details

### 1. Simple LLM Example (`01_simple_llm_example.rb`)

**Purpose**: Basic OpenAI GPT integration
**Key Features**:
- Simple workflow definition
- GPT-4o-mini model usage
- Error handling and logging
- Token usage tracking

**Usage**:
```ruby
agent = SimpleAgent.new
result = agent.get_ai_response("What is Ruby on Rails?")
puts result.output_for(:get_response)
```

### 2. Web Search Example (`02_web_search_example.rb`)

**Purpose**: Real-time web search with AI
**Key Features**:
- Web search integration
- Location-based queries
- Technology trends analysis
- Batch processing

**Usage**:
```ruby
agent = WebSearchAgent.new
result = agent.basic_search("Latest AI developments")
result = agent.location_search("restaurants", location: "London")
```

### 3. Vector Store Example (`03_vector_store_example.rb`)

**Purpose**: Document indexing and semantic search
**Key Features**:
- File upload to OpenAI
- Vector store creation
- Semantic search queries
- Multi-document knowledge base

**Usage**:
```ruby
agent = VectorStoreAgent.new
agent.upload_and_create_vector_store("document.txt")
agent.search_vector_store(store_id, "What is AI?")
```

### 4. Legal PDF Analysis (`04_legal_pdf_analysis.rb`)

**Purpose**: Comprehensive legal document analysis
**Key Features**:
- PDF upload and processing
- Multi-stage legal analysis
- Risk assessment
- Compliance checking
- Report generation

**Requirements**:
- `samplerenting.pdf` in the workflows directory
- Or modify the file path in the script

**Usage**:
```ruby
agent = LegalAnalysisAgent.new
results = agent.analyze_pdf_document("legal_contract.pdf")
report = agent.generate_compliance_report(results)
```

### 5. Image Generation Example (`05_image_generation_example.rb`)

**Purpose**: DALL-E 3 image generation
**Key Features**:
- Basic and HD image generation
- Multiple styles and formats
- Technical diagrams
- Batch processing

**Usage**:
```ruby
agent = ImageGenerationAgent.new
result = agent.generate_basic_image("Modern workspace")
result = agent.generate_hd_image("Futuristic AI interface")
```

## 💰 Cost Estimation

| Example | Tokens | API Calls | Estimated Cost |
|---------|--------|-----------|----------------|
| Simple LLM | ~1K tokens | 3 calls | $0.01-0.05 |
| Web Search | ~2K tokens | 4+ calls | $0.05-0.15 |
| Vector Store | ~500 tokens | 5+ calls | $0.01-0.05 |
| Legal Analysis | ~3K tokens | 4+ calls | $0.10-0.50 |
| Image Generation | N/A | 6+ images | $0.10-0.50 |

**Total for all examples**: ~$0.50-2.00

## 🔄 Migration from rdawn

### Key Changes

| rdawn | SuperAgent |
|-------|------------|
| `rdawn_workflow` | `SuperAgent::WorkflowDefinition` |
| `llm_task` | `:llm` (tool type) |
| `define_task` | `steps do ... end` |
| `context[:key]` | `{{key}}` (template variables) |
| `openai_api_key=` | `api_key=` |

### Example Migration

**Old (rdawn)**:
```ruby
class OldWorkflow < Rdawn::Workflow
  llm_task :analyze do |config|
    config.model = "gpt-4"
    config.prompt = "Analyze: #{context[:text]}"
  end
end
```

**New (SuperAgent)**:
```ruby
class NewWorkflow < SuperAgent::WorkflowDefinition
  steps do
    step :analyze, uses: :llm, with: {
      model: "gpt-4",
      messages: [
        { role: "system", content: "Analyze documents" },
        { role: "user", content: "{{text}}" }
      ]
    }
  end
end
```

## 🛠️ Development

### Adding New Examples

1. Create new `.rb` file in this directory
2. Follow the established pattern:
   - Include configuration
   - Define workflow class
   - Create agent class  
   - Add usage examples
   - Include error handling

### Testing Examples

```bash
# Syntax check all examples
ruby -c *.rb

# Run with test mode (dry run)
SUPERAGENT_DRY_RUN=true ruby example.rb

# Run with debug logging
SUPERAGENT_LOG_LEVEL=debug ruby example.rb
```

## 📊 Monitoring

### Logging
All examples include comprehensive logging:
- Request/response details
- Token usage tracking
- Error handling
- Progress indicators

### Cost Tracking
Each example displays estimated costs and actual usage:
- Token consumption
- API call counts
- Running totals

## 🔐 Security

### API Key Management
- Never commit API keys to version control
- Use environment variables or `.env` files
- Rotate keys regularly

### Data Handling
- Sensitive documents are processed securely
- Temporary files are cleaned up
- No persistent storage of sensitive data

## 📞 Support

### Common Issues

1. **"Tool not found" error**: Ensure using correct tool names (`:llm`, `:image_generation`, etc.)
2. **Invalid API key**: Check environment variable is set correctly
3. **Rate limiting**: Add delays between API calls
4. **File not found**: Verify paths and file existence

### Getting Help

- Check the setup script: `./setup_examples.sh`
- Review error messages for specific guidance
- Ensure all dependencies are installed
- Verify OpenAI API key has necessary permissions

## 🎯 Next Steps

After running these examples:

1. **Integrate with Rails**: See `../super_agent/examples/rails_integration.rb`
2. **Create custom workflows**: Build on these patterns
3. **Add streaming**: Implement real-time updates
4. **Background processing**: Use ActiveJob integration
5. **Production deployment**: Configure for production use

## 📈 Roadmap

- [ ] Streaming examples
- [ ] Batch processing examples  
- [ ] Error recovery patterns
- [ ] Performance optimization
- [ ] Advanced use cases
- [ ] Integration examples with popular gems