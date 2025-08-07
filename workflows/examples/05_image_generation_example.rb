#!/usr/bin/env ruby
# frozen_string_literal: true

# SuperAgent Image Generation Example
# This example demonstrates how to generate images using DALL-E with SuperAgent
# Shows various image generation capabilities and techniques

require 'bundler/setup'
require 'dotenv'
Dotenv.load('../.env')
require 'super_agent'
require 'fileutils'
require 'base64'

# Check if OpenAI API key is set
unless ENV['OPENAI_API_KEY']
  puts "❌ Error: Please set your OpenAI API key:"
  puts "export OPENAI_API_KEY='your-openai-api-key-here'"
  puts ""
  puts "Get your API key at: https://platform.openai.com/api-keys"
  exit 1
end

puts "🎨 SuperAgent Image Generation Example"
puts "=" * 50
puts "Demonstrating DALL-E image generation with SuperAgent"
puts ""

# Configure SuperAgent
SuperAgent.configure do |config|
  config.api_key = ENV['OPENAI_API_KEY']
  config.logger = Logger.new(STDOUT)
  config.logger.level = Logger::INFO
end

# Define workflows for image generation
class BasicImageGenerationWorkflow < SuperAgent::WorkflowDefinition
  steps do
    step :generate_image, uses: :image_generation, with: {
      model: "dall-e-3",
      size: "1024x1024",
      quality: "standard",
      response_format: "url",
      prompt: "{{prompt}}"
    }
  end
end

class HighQualityImageWorkflow < SuperAgent::WorkflowDefinition
  steps do
    step :generate_hd, uses: :image_generation, with: {
      model: "dall-e-3",
      size: "1792x1024",
      quality: "hd",
      response_format: "url",
      prompt: "{{prompt}}"
    }
  end
end

class VariationImageWorkflow < SuperAgent::WorkflowDefinition
  steps do
    step :create_variation, uses: :image_generation, with: {
      model: "dall-e-2",
      size: "512x512",
      response_format: "url",
      prompt: "{{prompt}}"
    }
  end
end

# Create image generation agent
class ImageGenerationAgent < SuperAgent::Base
  def generate_basic_image(prompt, style: "realistic")
    enhanced_prompt = "#{prompt}, #{style} style, high quality, detailed"
    initial_input = { prompt: enhanced_prompt }
    run_workflow(BasicImageGenerationWorkflow, initial_input: initial_input)
  end

  def generate_hd_image(prompt, style: "professional")
    enhanced_prompt = "#{prompt}, #{style} style, ultra high definition, professional photography"
    initial_input = { prompt: enhanced_prompt }
    run_workflow(HighQualityImageWorkflow, initial_input: initial_input)
  end

  def generate_variation(prompt, base_style: "artistic")
    enhanced_prompt = "#{prompt}, #{base_style} variation, creative interpretation"
    initial_input = { prompt: enhanced_prompt }
    run_workflow(VariationImageWorkflow, initial_input: initial_input)
  end
end

# Helper method to download and save image
def save_image(image_url, filename)
  require 'open-uri'
  
  begin
    File.open(filename, 'wb') do |file|
      URI.open(image_url) do |response|
        file.write(response.read)
      end
    end
    puts "✅ Image saved: #{filename}"
    true
  rescue => e
    puts "❌ Failed to save image: #{e.message}"
    false
  end
end

# Example usage
begin
  puts "🚀 Initializing SuperAgent Image Generation..."
  
  agent = ImageGenerationAgent.new
  output_dir = "../outputs/images"
  FileUtils.mkdir_p(output_dir)
  
  # Define image generation prompts
  prompts = [
    {
      type: :basic,
      prompt: "A modern Ruby on Rails developer workspace with multiple monitors showing code",
      filename: "rails_developer_workspace.png",
      style: "modern professional"
    },
    {
      type: :hd,
      prompt: "Futuristic AI assistant interface with holographic displays and neural networks",
      filename: "ai_assistant_interface.png",
      style: "futuristic tech"
    },
    {
      type: :basic,
      prompt: "SuperAgent logo design with clean minimalist style and AI theme",
      filename: "superagent_logo_concept.png",
      style: "minimalist clean"
    },
    {
      type: :basic,
      prompt: "Data visualization dashboard showing AI workflow analytics",
      filename: "ai_dashboard.png",
      style: "clean data visualization"
    },
    {
      type: :hd,
      prompt: "Elegant business meeting scene with AI presentation holograms",
      filename: "business_ai_presentation.png",
      style: "elegant corporate"
    },
    {
      type: :variation,
      prompt: "Abstract representation of machine learning concepts with neural pathways",
      filename: "ml_abstract_art.png",
      style: "abstract artistic"
    }
  ]
  
  generated_images = []
  
  prompts.each_with_index do |prompt_config, index|
    puts "\n🎨 Generating Image #{index + 1}/#{prompts.length}"
    puts "Prompt: #{prompt_config[:prompt]}"
    puts "Style: #{prompt_config[:style]}"
    puts "-" * 40
    
    # Generate image based on type
    case prompt_config[:type]
    when :basic
      result = agent.generate_basic_image(prompt_config[:prompt], style: prompt_config[:style])
    when :hd
      result = agent.generate_hd_image(prompt_config[:prompt], style: prompt_config[:style])
    when :variation
      result = agent.generate_variation(prompt_config[:prompt], base_style: prompt_config[:style])
    end
    
    if result.success?
      image_data = result.output_for(:generate_image) || result.output_for(:generate_hd) || result.output_for(:create_variation)
      
      if image_data.is_a?(Hash)
        image_url = image_data[:url]
      else
        image_url = image_data
      end
      
      filename = File.join(output_dir, prompt_config[:filename])
      
      if image_url && save_image(image_url, filename)
        generated_images << {
          prompt: prompt_config[:prompt],
          filename: filename,
          url: image_url,
          size: prompt_config[:type] == :hd ? "1792x1024" : "1024x1024"
        }
        puts "✅ Generated successfully!"
      end
    else
      puts "❌ Generation failed: #{result.error}"
    end
    
    # Small delay to avoid rate limiting
    sleep(1) if index < prompts.length - 1
  end
  
  # Generate specialized images for different use cases
  puts "\n" + "=" * 50
  puts "🎯 Generating Specialized Images"
  puts ""
  
  # Technical documentation images
  technical_prompts = [
    {
      type: "architecture_diagram",
      prompt: "Technical architecture diagram showing SuperAgent workflow system with LLM integration",
      filename: "superagent_architecture.png"
    },
    {
      type: "flowchart",
      prompt: "Clean flowchart showing AI task processing pipeline with decision points",
      filename: "ai_pipeline_flowchart.png"
    }
  ]
  
  technical_prompts.each do |tech_prompt|
    puts "🔧 Generating #{tech_prompt[:type]}: #{tech_prompt[:prompt]}"
    
    result = agent.generate_basic_image(tech_prompt[:prompt], style: "technical diagram")
    
    if result.success?
      image_data = result.output_for(:generate_image)
      if image_data.is_a?(Hash)
        image_url = image_data[:url]
      else
        image_url = image_data
      end
      
      filename = File.join(output_dir, tech_prompt[:filename])
      
      if image_url && save_image(image_url, filename)
        generated_images << {
          prompt: tech_prompt[:prompt],
          filename: filename,
          url: image_url,
          type: tech_prompt[:type]
        }
      end
    end
  end
  
  # Generate images with different styles
  puts "\n🎨 Generating Style Variations"
  
  style_variations = [
    {
      prompt: "Modern SaaS dashboard interface for AI workflow management",
      styles: ["flat design", "3D realistic", "minimalist", "material design"],
      base_filename: "dashboard_styles"
    }
  ]
  
  style_variations.each do |variation|
    variation[:styles].each_with_index do |style, idx|
      puts "🎨 Generating #{style} style..."
      
      styled_prompt = "#{variation[:prompt]}, #{style} style"
      filename = File.join(output_dir, "#{variation[:base_filename]}_#{style.gsub(' ', '_')}.png")
      
      result = agent.generate_basic_image(styled_prompt, style: style)
      
      if result.success?
        image_data = result.output_for(:generate_image)
        if image_data.is_a?(Hash)
          image_url = image_data[:url]
        else
          image_url = image_data
        end
        save_image(image_url, filename) if image_url
      end
    end
  end

rescue => e
  puts "❌ Error during image generation: #{e.message}"
  puts "🔧 Error details: #{e.backtrace.first(3).join("\n")}"
end

# Display results
puts "\n" + "=" * 50
puts "🎉 Image Generation Complete!"
puts ""

if generated_images.any?
  puts "📸 Generated Images:"
  generated_images.each_with_index do |img, index|
    puts "#{index + 1}. #{File.basename(img[:filename])}"
    puts "   Prompt: #{img[:prompt][0..50]}..."
    puts "   File: #{img[:filename]}"
    puts ""
  end
end

puts "📁 All images saved to: #{output_dir}"
puts ""
puts "💡 This example demonstrated:"
puts "   • Basic DALL-E 3 image generation"
puts "   • High-quality HD image generation"
puts "   • Different image sizes and formats"
puts "   • Style variations and artistic interpretations"
puts "   • Technical diagram generation"
puts "   • Batch image processing"
puts ""
puts "💰 Estimated cost: ~$0.10-0.50 (multiple image generations)"
puts "🎨 Perfect for: Marketing materials, technical diagrams, UI concepts, artistic content"