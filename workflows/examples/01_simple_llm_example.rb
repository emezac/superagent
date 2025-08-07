#!/usr/bin/env ruby
# frozen_string_literal: true

# SuperAgent Simple LLM Example
# This example demonstrates real OpenAI API calls using SuperAgent's LLMTask
# Migration from rdawn to SuperAgent framework

require 'bundler/setup'
require 'dotenv'
Dotenv.load('../.env')
require 'super_agent'

# Check if OpenAI API key is set
unless ENV['OPENAI_API_KEY']
  puts "❌ Error: Please set your OpenAI API key:"
  puts "export OPENAI_API_KEY='your-openai-api-key-here'"
  puts ""
  puts "Get your API key at: https://platform.openai.com/api-keys"
  exit 1
end

puts "🤖 SuperAgent Simple LLM Example"
puts "=" * 40
puts "Making a real API call to OpenAI using SuperAgent..."

# Configure SuperAgent
SuperAgent.configure do |config|
  config.api_key = ENV['OPENAI_API_KEY']
  config.logger = Logger.new(STDOUT)
  config.logger.level = Logger::INFO
end

# Define a simple workflow for getting AI responses
class SimpleAIWorkflow < SuperAgent::WorkflowDefinition
  steps do
    step :get_response, uses: :llm_task, with: {
      model: "gpt-4o-mini",
      max_tokens: 300,
      temperature: 0.7,
      messages: [
        { role: "system", content: "You are a helpful AI assistant that provides concise, accurate information." },
        { role: "user", content: "{{prompt}}" }
      ]
    }
  end
end

# Create a simple agent for testing
class SimpleAgent < SuperAgent::Base
  def get_ai_response(user_prompt)
    initial_input = { prompt: user_prompt }
    run_workflow(SimpleAIWorkflow, initial_input: initial_input)
  end
end

# Example usage
begin
  puts "🚀 Initializing SuperAgent..."
  
  # Create the agent
  agent = SimpleAgent.new
  
  # Test prompts
  test_prompts = [
    "What are the latest news developments about AI in 2025? Please provide a brief summary.",
    "Explain Ruby on Rails in simple terms for beginners.",
    "What are the key differences between Ruby and Python?"
  ]
  
  test_prompts.each_with_index do |prompt, index|
    puts "\n🔍 Test #{index + 1}: #{prompt[0..50]}..."
    puts "-" * 40
    
    # Execute the workflow
    result = agent.get_ai_response(prompt)
    
    if result.success?
      puts "✅ Success!"
      puts "🤖 AI Response:"
      puts result.output_for(:get_response)
      puts ""
      puts "⏱️ Duration: #{result.duration_ms}ms"
    else
      puts "❌ Error: #{result.error}"
    end
    
    puts "\n" + "=" * 50
  end

rescue => e
  puts "❌ Error during execution: #{e.message}"
  puts "🔧 Error details: #{e.backtrace.first(3).join("\n")}"
end

puts "\n🎉 SuperAgent LLM example complete!"
puts "💡 This example demonstrated:"
puts "   • SuperAgent configuration"
puts "   • Workflow definition with LLMTask"
puts "   • Simple agent creation"
puts "   • Real OpenAI API integration"
puts "   • Error handling and logging"