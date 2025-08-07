# 🚀 SuperAgent Real-World Examples

This directory contains comprehensive examples demonstrating how to use SuperAgent with real OpenAI API calls. These examples replace the old rdawn-based workflows with modern SuperAgent implementations.

## 📋 Table of Contents

1. [Getting Started](#getting-started)
2. [Available Examples](#available-examples)
3. [Setup Instructions](#setup-instructions)
4. [Usage Guide](#usage-guide)
5. [Cost Estimates](#cost-estimates)
6. [Troubleshooting](#troubleshooting)

## 🏁 Getting Started

### Prerequisites

- Ruby 3.0+
- OpenAI API key
- SuperAgent gem installed

### Quick Setup

1. **Install SuperAgent gem:**
   ```bash
   gem install super_agent
   ```

2. **Set your OpenAI API key:**
   ```bash
   export OPENAI_API_KEY='your-openai-api-key-here'
   ```

3. **Run any example:**
   ```bash
   cd workflows/examples
   ruby 01_simple_llm_example.rb
   ```

## 🎯 Available Examples

### 1. Simple LLM Example (`01_simple_llm_example.rb`)
- **Purpose**: Basic OpenAI GPT-4 integration
- **Features**: Simple prompts, multiple test cases, error handling
- **Cost**: ~$0.01-0.05

### 2. Web Search Example (`02_web_search_example.rb`)
- **Purpose**: Real-time web search with OpenAI
- **Features**: Location-based search, batch queries, tech trends
- **Cost**: ~$0.05-0.15

### 3. Vector Store Example (`03_vector_store_example.rb`)
- **Purpose**: Document indexing and semantic search
- **Features**: File upload, vector store creation, semantic queries
- **Cost**: ~$0.01-0.05

### 4. Legal PDF Analysis (`04_legal_pdf_analysis.rb`)
- **Purpose**: Analyze legal documents using the provided samplerenting.pdf
- **Features**: PDF upload, clause extraction, risk assessment, compliance checking
- **Cost**: ~$0.10-0.50

### 5. Image Generation (`05_image_generation_example.rb`)
- **Purpose**: DALL-E 3 image generation
- **Features**: Multiple styles, HD quality, technical diagrams, variations
- **Cost**: ~$0.10-0.50

## 🔧 Setup Instructions

### 1. Environment Setup

```bash
# Create a new directory for your project
mkdir superagent-examples && cd superagent-examples

# Create Gemfile
cat > Gemfile << 'EOF'
source 'https://rubygems.org'

gem 'super_agent'
gem 'bundler'
EOF

# Install dependencies
bundle install
```

### 2. API Key Configuration

```bash
# Add to your shell profile (e.g., ~/.bashrc, ~/.zshrc)
export OPENAI_API_KEY='sk-your-key-here'

# Reload your shell or source the file
source ~/.bashrc
```

### 3. Verify Installation

```bash
# Test your setup
ruby -e "require 'super_agent'; puts 'SuperAgent loaded successfully!'"
```

## 🚀 Usage Guide

### Running Individual Examples

Each example is self-contained and includes detailed console output:

```bash
# Navigate to examples directory
cd workflows/examples

# Run specific example
ruby 01_simple_llm_example.rb
ruby 02_web_search_example.rb
ruby 03_vector_store_example.rb
ruby 04_legal_pdf_analysis.rb
ruby 05_image_generation_example.rb
```

### Custom Usage

#### Basic LLM Task
```ruby
require 'super_agent'

class MyAgent < SuperAgent::Base
  def ask_question(question)
    workflow = Class.new(SuperAgent::WorkflowDefinition) do
      define_task :answer, :llm do |config|
        config.model = "gpt-4o-mini"
        config.system_prompt = "You are a helpful assistant."
        config.max_tokens = 300
      end
    end
    
    run_workflow(workflow, initial_input: { question: question })
  end
end

agent = MyAgent.new
result = agent.ask_question("What is Ruby on Rails?")
puts result.final_output[:answer][:content] if result.success?
```

#### Web Search
```ruby
class SearchAgent < SuperAgent::Base
  def search_web(query)
    workflow = Class.new(SuperAgent::WorkflowDefinition) do
      define_task :search, :llm do |config|
        config.model = "gpt-4o"
        config.web_search = true
        config.max_tokens = 500
      end
    end
    
    run_workflow(workflow, initial_input: { query: query })
  end
end
```

## 💰 Cost Estimates

| Example | Estimated Cost | API Calls |
|---------|----------------|-----------|
| Simple LLM | $0.01-0.05 | 1-3 |
| Web Search | $0.05-0.15 | 3-6 |
| Vector Store | $0.01-0.05 | 4-8 |
| Legal Analysis | $0.10-0.50 | 5-10 |
| Image Generation | $0.10-0.50 | 5-8 |

**Note**: Costs are approximate and based on current OpenAI pricing. Actual costs may vary.

## 🔍 Example Features

### Core Capabilities Demonstrated

- ✅ **LLM Integration**: GPT-4, GPT-4o, GPT-4o-mini
- ✅ **Web Search**: Real-time information retrieval
- ✅ **Vector Stores**: Document indexing and semantic search
- ✅ **File Upload**: PDF, text, and document processing
- ✅ **Image Generation**: DALL-E 3 with various styles
- ✅ **Error Handling**: Comprehensive error management
- ✅ **Rate Limiting**: Built-in request pacing
- ✅ **Logging**: Detailed execution logs

### Advanced Features

- **Streaming**: Real-time response updates
- **Async Processing**: Background job execution
- **Context Management**: Persistent conversation state
- **Tool Integration**: Web search, file operations, image generation
- **Custom Workflows**: Reusable workflow definitions

## 🛠️ Troubleshooting

### Common Issues

#### 1. API Key Not Found
```bash
❌ Error: Please set your OpenAI API key

# Solution
export OPENAI_API_KEY='your-key-here'
echo $OPENAI_API_KEY  # Verify it's set
```

#### 2. Rate Limiting
```bash
❌ Error: Rate limit exceeded

# Solution: Add delays between requests
sleep(1) between API calls
```

#### 3. Network Issues
```bash
❌ Error: Connection timeout

# Solution: Check internet connection and OpenAI status
ping api.openai.com
```

#### 4. File Not Found
```bash
❌ Error: PDF file not found

# Solution: Ensure samplerenting.pdf is in workflows/
ls ../workflows/samplerenting.pdf
```

### Debug Mode

Enable verbose logging:

```ruby
SuperAgent.configure do |config|
  config.logger.level = Logger::DEBUG
end
```

## 📊 Monitoring Usage

### Check OpenAI Dashboard
- Visit: https://platform.openai.com/usage
- Monitor API calls and costs
- Set usage limits

### Local Monitoring
Examples include usage tracking in output:

```bash
💰 Usage: {"prompt_tokens": 45, "completion_tokens": 150, "total_tokens": 195}
```

## 🔗 Additional Resources

- [SuperAgent Documentation](https://github.com/your-org/super_agent)
- [OpenAI API Documentation](https://platform.openai.com/docs)
- [Ruby OpenAI Gem](https://github.com/alexrudall/ruby-openai)
- [OpenAI Pricing](https://openai.com/pricing)

## 🤝 Contributing

Found a bug or want to add an example? Please:

1. Fork the repository
2. Create a new example file
3. Follow the existing code patterns
4. Add your example to this README
5. Submit a pull request

## 📄 License

These examples are provided under the MIT License. See LICENSE file for details.

## 🆘 Support

- **Issues**: Report bugs via GitHub issues
- **Questions**: Use GitHub discussions
- **Documentation**: Check the SuperAgent wiki

---

**Happy coding with SuperAgent!** 🚀