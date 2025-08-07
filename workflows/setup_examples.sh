#!/bin/bash

# SuperAgent Examples Setup Script
echo "🚀 Setting up SuperAgent Examples..."

# Check if OpenAI API key is set
if [ -z "$OPENAI_API_KEY" ]; then
    echo "❌ OPENAI_API_KEY is not set"
    echo ""
    echo "Please set your OpenAI API key:"
    echo "export OPENAI_API_KEY='your-openai-api-key-here'"
    echo ""
    echo "You can get your API key at: https://platform.openai.com/api-keys"
    echo ""
    echo "After setting the key, run:"
    echo "bundle exec ruby examples/01_simple_llm_example.rb"
    exit 1
fi

echo "✅ OPENAI_API_KEY is set"
echo "🔧 Running bundle install..."
bundle install

echo ""
echo "🎯 Available examples:"
echo "1. Simple LLM:        bundle exec ruby examples/01_simple_llm_example.rb"
echo "2. Web Search:       bundle exec ruby examples/02_web_search_example.rb"
echo "3. Vector Store:     bundle exec ruby examples/03_vector_store_example.rb"
echo "4. Legal PDF:        bundle exec ruby examples/04_legal_pdf_analysis.rb"
echo "5. Image Generation: bundle exec ruby examples/05_image_generation_example.rb"
echo ""
echo "💡 Tip: Add this to your shell profile for permanent setup:"
echo "echo 'export OPENAI_API_KEY=\"your-key-here\"' >> ~/.bashrc"
echo "source ~/.bashrc"