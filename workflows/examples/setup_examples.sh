#!/bin/bash

# SuperAgent Examples Setup Script
# This script helps set up and run the SuperAgent examples with real OpenAI API calls

set -e

echo "🚀 Setting up SuperAgent Examples Environment"
echo "============================================"

# Check if Ruby is installed
if ! command -v ruby &> /dev/null; then
    echo "❌ Ruby is not installed. Please install Ruby 3.3.0 or later."
    exit 1
fi

# Check Ruby version
RUBY_VERSION=$(ruby -v | cut -d' ' -f2)
echo "📦 Ruby version: $RUBY_VERSION"

# Check if bundler is installed
if ! command -v bundle &> /dev/null; then
    echo "📦 Installing bundler..."
    gem install bundler
fi

# Install dependencies
echo "📦 Installing dependencies..."
bundle install

# Create output directories
echo "📁 Creating output directories..."
mkdir -p ../outputs/images
mkdir -p ../outputs/reports

# Check for samplerenting.pdf
echo "📄 Checking for legal document..."
if [ ! -f "../samplerenting.pdf" ]; then
    echo "⚠️  samplerenting.pdf not found in workflows directory"
    echo "   You can add any PDF file named 'samplerenting.pdf' for legal analysis"
    echo "   Or modify 04_legal_pdf_analysis.rb to use your own PDF file"
else
    echo "✅ Found samplerenting.pdf for legal analysis"
fi

# Check for OpenAI API key
echo "🔑 Checking OpenAI API key configuration..."
if [ -z "$OPENAI_API_KEY" ]; then
    echo "❌ OPENAI_API_KEY environment variable is not set"
    echo ""
    echo "To get started:"
    echo "1. Get your API key from: https://platform.openai.com/api-keys"
    echo "2. Set your API key:"
    echo "   export OPENAI_API_KEY='your-openai-api-key-here'"
    echo ""
    echo "Or create a .env file:"
    echo "   echo 'OPENAI_API_KEY=your-key-here' > ../.env"
    echo ""
    echo "Then run the examples:"
    echo "   ruby 01_simple_llm_example.rb"
    echo "   ruby 02_web_search_example.rb"
    echo "   ruby 03_vector_store_example.rb"
    echo "   ruby 04_legal_pdf_analysis.rb"
    echo "   ruby 05_image_generation_example.rb"
    exit 1
else
    echo "✅ OpenAI API key is configured"
fi

# Test basic connectivity
echo "🧪 Testing OpenAI API connectivity..."
ruby -e "
require 'super_agent'
SuperAgent.configure { |config| config.api_key = ENV['OPENAI_API_KEY'] }
begin
  puts '✅ SuperAgent configured successfully'
rescue => e
  puts \"❌ Configuration error: #{e.message}\"
  exit 1
end
"

# Make scripts executable
chmod +x *.rb

echo ""
echo "🎉 Setup Complete!"
echo "=================="
echo ""
echo "📂 Directory structure:"
echo "   workflows/"
echo "   ├── examples/                   # SuperAgent examples"
echo "   ├── outputs/                    # Generated outputs"
echo "   │   ├── images/                 # Generated images"
echo "   │   └── reports/                # Analysis reports"
echo ""
echo "🚀 Ready to run examples:"
echo ""
echo "1. Simple LLM:            ruby 01_simple_llm_example.rb"
echo "2. Web Search:            ruby 02_web_search_example.rb" 
echo "3. Vector Store:          ruby 03_vector_store_example.rb"
echo "4. Legal PDF Analysis:    ruby 04_legal_pdf_analysis.rb"
echo "5. Image Generation:      ruby 05_image_generation_example.rb"
echo ""
echo "💡 Tips:"
echo "   • Start with 01_simple_llm_example.rb to test basic functionality"
echo "   • Check ../outputs/ for generated files"
echo "   • Each example shows estimated costs"
echo "   • Examples include comprehensive error handling"
echo ""
echo "💰 Estimated costs for full run: ~$0.50-2.00"