#!/usr/bin/env ruby
# frozen_string_literal: true

# SuperAgent Web Search Example
# This example demonstrates how to use OpenAI's web search tool with SuperAgent
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

puts "🌐 SuperAgent Web Search Example"
puts "=" * 50
puts "Demonstrating real-time web search capabilities with SuperAgent"
puts ""

# Configure SuperAgent
SuperAgent.configure do |config|
  config.api_key = ENV['OPENAI_API_KEY']
  config.logger = Logger.new(STDOUT)
  config.logger.level = Logger::INFO
end

# Define workflows for different search types
class BasicSearchWorkflow < SuperAgent::WorkflowDefinition
  steps do
    step :search, uses: :llm, with: {
      model: "gpt-4o",
      max_tokens: 500,
      temperature: 0.7,
      web_search: true,
      messages: [
        { role: "system", content: "You are a helpful assistant that searches the web for current information." },
        { role: "user", content: "{{prompt}}" }
      ]
    }
  end
end

class LocationSearchWorkflow < SuperAgent::WorkflowDefinition
  steps do
    step :search, uses: :llm, with: {
      model: "gpt-4o",
      max_tokens: 400,
      temperature: 0.7,
      web_search: true,
      messages: [
        { role: "system", content: "You are a local guide providing information about places and services." },
        { role: "user", content: "{{prompt}}" }
      ]
    }
  end
end

class TechTrendsWorkflow < SuperAgent::WorkflowDefinition
  steps do
    step :search_trends, uses: :llm, with: {
      model: "gpt-4o",
      messages: [
        { role: "system", content: "You are a technology analyst providing insights on current trends." },
        { role: "user", content: "{{prompt}}" }
      ],
      web_search: true,
      max_tokens: 600
    }
  end
end

# Create web search agent
class WebSearchAgent < SuperAgent::Base
  def basic_search(query)
    initial_input = { prompt: query }
    run_workflow(BasicSearchWorkflow, initial_input: initial_input)
  end

  def location_search(query, location: nil)
    prompt = location ? "#{query} in #{location}" : query
    initial_input = { prompt: prompt }
    run_workflow(LocationSearchWorkflow, initial_input: initial_input)
  end

  def tech_trends_search(topic)
    initial_input = { prompt: topic }
    run_workflow(TechTrendsWorkflow, initial_input: initial_input)
  end
end

# Example usage
begin
  puts "🚀 Initializing SuperAgent Web Search..."
  
  agent = WebSearchAgent.new
  
  # Step 1: Basic web search
  puts "=== Step 1: Basic Web Search ==="
  puts "🔍 Searching for latest positive news..."
  
  result1 = agent.basic_search("What was a positive news story from today?")
  
  if result1.success?
    puts "✅ Search successful!"
    puts "📄 Result:"
    puts result1.output_for(:search)
    puts "⏱️ Duration: #{result1.duration_ms}ms"
  else
    puts "❌ Search error: #{result1.error}"
  end
  
  puts "\n" + "-" * 50
  
  # Step 2: Location-based search
  puts "=== Step 2: Location-Based Search ==="
  puts "🗺️ Searching for restaurants in London..."
  
  result2 = agent.location_search(
    "What are the best restaurants around Granary Square?",
    location: "London, UK"
  )
  
  if result2.success?
    puts "✅ Location search successful!"
    puts "📍 Location: London, UK"
    puts "📄 Result:"
    puts result2.output_for(:search)
  else
    puts "❌ Location search error: #{result2.error}"
  end
  
  puts "\n" + "-" * 50
  
  # Step 3: Tech trends search
  puts "=== Step 3: Tech Trends Search ==="
  puts "🔬 Searching for latest AI developments..."
  
  result3 = agent.tech_trends_search("Latest AI developments 2025")
  
  if result3.success?
    puts "✅ Tech trends search successful!"
    puts "📊 Result:"
    puts result3.output_for(:search_trends)
  else
    puts "❌ Tech search error: #{result3.error}"
  end
  
  puts "\n" + "-" * 50
  
  # Step 4: Multiple focused searches
  puts "=== Step 4: Batch Search Topics ==="
  
  search_topics = [
    "Recent breakthroughs in quantum computing",
    "Latest developments in renewable energy",
    "Space exploration news 2025",
    "Cybersecurity trends and threats"
  ]
  
  search_topics.each_with_index do |topic, index|
    puts "#{index + 1}. Searching: #{topic}"
    puts "🔍 Processing..."
    
    result = agent.basic_search(topic)
    
    if result.success?
      puts "✅ Success!"
      summary = result.output_for(:search).to_s[0..150]
      puts "📄 Summary: #{summary}..."
    else
      puts "❌ Error: #{result.error}"
    end
    
    puts "─" * 40
  end

rescue => e
  puts "❌ Error during execution: #{e.message}"
  puts "🔧 Error details: #{e.backtrace.first(3).join("\n")}"
end

puts "\n" + "=" * 50
puts "🎉 SuperAgent Web Search Example Complete!"
puts ""
puts "💡 This example demonstrated:"
puts "   • Basic web search with SuperAgent"
puts "   • Location-based queries"
puts "   • Technology trends analysis"
puts "   • Batch processing of multiple searches"
puts "   • Real-time web search integration"
puts ""
puts "💰 Estimated cost: ~$0.05-0.15 (multiple searches)"