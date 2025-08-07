#!/usr/bin/env ruby
# frozen_string_literal: true

# Advanced Markdown Generation with SuperAgent
# This example demonstrates AI-powered markdown generation for documentation,
# reports, technical specifications, and content creation

require 'bundler/setup'
require 'dotenv'
Dotenv.load('../.env')
require 'super_agent'
require 'fileutils'
require 'date'

puts "📝 SuperAgent Advanced Markdown Generation"
puts "=" * 50
puts "AI-powered documentation and content creation"
puts ""

# Configure SuperAgent
SuperAgent.configure do |config|
  config.api_key = ENV['OPENAI_API_KEY'] || 'dummy-key'
  config.logger = Logger.new(STDOUT)
  config.logger.level = Logger::INFO
end

# Define comprehensive markdown workflows
class TechnicalDocumentationWorkflow < SuperAgent::WorkflowDefinition
  steps do
    step :generate_structure, uses: :llm, with: {
      model: "gpt-4o",
      messages: [
        { role: "system", content: "You are a technical documentation expert. Create comprehensive, well-structured technical documentation in markdown format. Include sections, examples, and best practices." },
        { role: "user", content: "{{documentation_context}}" }
      ],
      max_tokens: 2000
    }
    
    step :enhance_examples, uses: :llm, with: {
      model: "gpt-4o-mini",
      messages: [
        { role: "system", content: "Enhance technical documentation with practical code examples, diagrams description, and implementation details." },
        { role: "user", content: "{{enhancement_context}}" }
      ],
      max_tokens: 1000
    }
  end
end

class BusinessReportWorkflow < SuperAgent::WorkflowDefinition
  steps do
    step :analyze_data, uses: :llm, with: {
      model: "gpt-4o",
      messages: [
        { role: "system", content: "You are a business analyst. Analyze provided data and create executive-level business reports with insights and recommendations." },
        { role: "user", content: "{{business_data}}" }
      ],
      max_tokens: 1500
    }
    
    step :format_report, uses: :markdown, with: {
      content: "{{report_content}}",
      title: "{{report_title}}",
      include_toc: true,
      format: 'business_report'
    }
  end
end

class APIReferenceWorkflow < SuperAgent::WorkflowDefinition
  steps do
    step :generate_endpoints, uses: :llm, with: {
      model: "gpt-4o",
      messages: [
        { role: "system", content: "You are an API documentation specialist. Create comprehensive API reference documentation with endpoints, parameters, responses, and examples." },
        { role: "user", content: "{{api_specification}}" }
      ],
      max_tokens: 1800
    }
    
    step :add_code_samples, uses: :llm, with: {
      model: "gpt-4o-mini",
      messages: [
        { role: "system", content: "Add practical code samples in multiple programming languages for API endpoints. Include authentication, error handling, and best practices." },
        { role: "user", content: "{{code_samples_context}}" }
      ],
      max_tokens: 1200
    }
  end
end

class TutorialWorkflow < SuperAgent::WorkflowDefinition
  steps do
    step :create_tutorial, uses: :llm, with: {
      model: "gpt-4o",
      messages: [
        { role: "system", content: "You are an expert tutorial writer. Create step-by-step tutorials with clear explanations, code examples, and troubleshooting tips." },
        { role: "user", content: "{{tutorial_request}}" }
      ],
      max_tokens: 2000
    }
    
    step :add_progressive_examples, uses: :llm, with: {
      model: "gpt-4o-mini",
      messages: [
        { role: "system", content: "Create progressive examples that build upon each other, suitable for learners at different skill levels." },
        { role: "user", content: "{{tutorial_content}}" }
      ],
      max_tokens: 800
    }
  end
end

class ReleaseNotesWorkflow < SuperAgent::WorkflowDefinition
  steps do
    step :analyze_changes, uses: :llm, with: {
      model: "gpt-4o",
      messages: [
        { role: "system", content: "You are a release notes writer. Create comprehensive, user-friendly release notes from technical change logs." },
        { role: "user", content: "{{changes_data}}" }
      ],
      max_tokens: 1200
    }
    
    step :categorize_features, uses: :llm, with: {
      model: "gpt-4o-mini",
      messages: [
        { role: "system", content: "Categorize release notes into sections: New Features, Improvements, Bug Fixes, Breaking Changes, and Documentation." },
        { role: "user", content: "{{release_content}}" }
      ],
      max_tokens: 600
    }
  end
end

# SuperAgent Markdown Generator
class SuperAgentMarkdownGenerator < SuperAgent::Base
  def initialize
    super
    @output_dir = "../outputs/markdown"
    FileUtils.mkdir_p(@output_dir)
  end

  def generate_technical_documentation(topic, options = {})
    puts "🛠️ Generating technical documentation for: #{topic}"
    
    documentation_request = {
      documentation_context: "Create comprehensive technical documentation for #{topic}. Include: introduction, architecture, setup instructions, usage examples, troubleshooting, and best practices. Target audience: #{options[:audience] || 'developers'}"
    }
    
    result = run_workflow(TechnicalDocumentationWorkflow, initial_input: documentation_request)
    
    if result.success?
      content = result.output_for(:generate_structure)
      enhanced = result.output_for(:enhance_examples)
      
      final_content = merge_content(content, enhanced)
      save_document("#{topic.downcase.gsub(' ', '_')}_documentation.md", final_content)
      
      { success: true, content: final_content, filename: "#{topic.downcase.gsub(' ', '_')}_documentation.md" }
    else
      { success: false, error: result.error }
    end
  end

  def generate_business_report(data, title)
    puts "📊 Generating business report: #{title}"
    
    business_data = {
      business_data: "Create business report from: #{data.to_json}. Title: #{title}"
    }
    
    result = run_workflow(BusinessReportWorkflow, initial_input: business_data)
    
    if result.success?
      content = result.output_for(:analyze_data)
      formatted = result.output_for(:format_report)
      
      final_content = format_business_report(title, content, formatted)
      save_document("#{title.downcase.gsub(' ', '_')}_report.md", final_content)
      
      { success: true, content: final_content, filename: "#{title.downcase.gsub(' ', '_')}_report.md" }
    else
      { success: false, error: result.error }
    end
  end

  def generate_api_reference(api_name, endpoints)
    puts "📚 Generating API reference for: #{api_name}"
    
    api_specification = {
      api_specification: "Create API reference documentation for #{api_name} with endpoints: #{endpoints.to_json}. Include authentication, rate limiting, error handling, and examples."
    }
    
    result = run_workflow(APIReferenceWorkflow, initial_input: api_specification)
    
    if result.success?
      content = result.output_for(:generate_endpoints)
      samples = result.output_for(:add_code_samples)
      
      final_content = merge_content(content, samples)
      save_document("#{api_name.downcase}_api_reference.md", final_content)
      
      { success: true, content: final_content, filename: "#{api_name.downcase}_api_reference.md" }
    else
      { success: false, error: result.error }
    end
  end

  def generate_tutorial(subject, skill_level = 'beginner')
    puts "📖 Generating tutorial: #{subject} (#{skill_level})"
    
    tutorial_request = {
      tutorial_request: "Create a #{skill_level} level tutorial for #{subject}. Include step-by-step instructions, explanations, common pitfalls, and troubleshooting tips."
    }
    
    result = run_workflow(TutorialWorkflow, initial_input: tutorial_request)
    
    if result.success?
      content = result.output_for(:create_tutorial)
      examples = result.output_for(:add_progressive_examples)
      
      final_content = merge_content(content, examples)
      save_document("#{subject.downcase.gsub(' ', '_')}_tutorial.md", final_content)
      
      { success: true, content: final_content, filename: "#{subject.downcase.gsub(' ', '_')}_tutorial.md" }
    else
      { success: false, error: result.error }
    end
  end

  def generate_release_notes(version, changes)
    puts "🚀 Generating release notes for: #{version}"
    
    changes_data = {
      changes_data: "Create release notes for version #{version} from changes: #{changes.to_json}"
    }
    
    result = run_workflow(ReleaseNotesWorkflow, initial_input: changes_data)
    
    if result.success?
      content = result.output_for(:analyze_changes)
      categorized = result.output_for(:categorize_features)
      
      final_content = format_release_notes(version, content, categorized)
      save_document("release_notes_#{version}.md", final_content)
      
      { success: true, content: final_content, filename: "release_notes_#{version}.md" }
    else
      { success: false, error: result.error }
    end
  end

  def generate_comparison_table(items, comparison_criteria)
    puts "📊 Generating comparison table..."
    
    comparison_context = {
      documentation_request: "Create a detailed comparison table for #{items.join(', ')} based on criteria: #{comparison_criteria.join(', ')}. Format as markdown table with clear sections."
    }
    
    result = run_workflow(TechnicalDocumentationWorkflow, initial_input: comparison_context)
    
    if result.success?
      content = result.output_for(:generate_structure)
      filename = "comparison_#{items.map(&:downcase).join('_')}.md"
      save_document(filename, content)
      
      { success: true, content: content, filename: filename }
    else
      { success: false, error: result.error }
    end
  end

  def batch_generate_documents(templates)
    puts "📦 Batch generating #{templates.length} documents..."
    
    results = []
    
    templates.each_with_index do |template, index|
      puts "  📄 #{index + 1}/#{templates.length}: #{template[:type]} - #{template[:title]}"
      
      result = case template[:type]
               when 'technical'
                 generate_technical_documentation(template[:title], template[:options])
               when 'business_report'
                 generate_business_report(template[:data], template[:title])
               when 'api_reference'
                 generate_api_reference(template[:title], template[:endpoints])
               when 'tutorial'
                 generate_tutorial(template[:subject], template[:level])
               when 'release_notes'
                 generate_release_notes(template[:version], template[:changes])
               when 'comparison'
                 generate_comparison_table(template[:items], template[:criteria])
               else
                 { success: false, error: "Unknown template type: #{template[:type]}" }
               end
      
      results << result.merge(template: template)
      sleep(1) # Rate limiting
    end
    
    success_count = results.count { |r| r[:success] }
    
    {
      success: true,
      total: results.length,
      successful: success_count,
      failed: results.length - success_count,
      results: results
    }
  end

  def create_documentation_package(project_name, components)
    puts "📦 Creating documentation package for: #{project_name}"
    
    package = [
      { type: 'technical', title: "#{project_name} Overview", options: { audience: 'developers' } },
      { type: 'api_reference', title: project_name, endpoints: components[:api_endpoints] },
      { type: 'tutorial', subject: "Getting Started with #{project_name}", level: 'beginner' },
      { type: 'business_report', data: components[:metrics], title: "#{project_name} Performance Report" },
      { type: 'release_notes', version: components[:version], changes: components[:changes] }
    ]
    
    batch_generate_documents(package)
  end

  private

  def merge_content(primary, secondary)
    primary_content = primary.is_a?(Hash) ? (primary[:content] || primary.to_s) : primary.to_s
    secondary_content = secondary.is_a?(Hash) ? (secondary[:content] || secondary.to_s) : secondary.to_s
    
    "#{primary_content}\n\n## Enhanced Examples\n\n#{secondary_content}"
  end

  def format_business_report(title, analysis, formatted)
    analysis_content = analysis.is_a?(Hash) ? (analysis[:content] || analysis.to_s) : analysis.to_s
    formatted_content = formatted.is_a?(Hash) ? (formatted[:content] || formatted.to_s) : formatted.to_s
    
    <<~REPORT
      # #{title}
      
      **Generated:** #{Date.today.strftime('%B %d, %Y')}
      
      ## Executive Summary
      #{analysis_content}
      
      ## Detailed Analysis
      #{formatted_content}
      
      ---
      *Report generated by SuperAgent AI*
    REPORT
  end

  def format_release_notes(version, content, categorized)
      content_text = content.is_a?(Hash) ? (content[:content] || content.to_s) : content.to_s
    categorized_text = categorized.is_a?(Hash) ? (categorized[:content] || categorized.to_s) : categorized.to_s
    
    <<~RELEASE
      # Release Notes - #{version}
      
      **Release Date:** #{Date.today.strftime('%B %d, %Y')}
      
      ## What's New
      
      #{content_text}
      
      ## Categorized Changes
      
      #{categorized_text}
      
      ---
      *Release notes generated by SuperAgent*
    RELEASE
  end

  def save_document(filename, content)
    filepath = File.join(@output_dir, filename)
    File.write(filepath, content.is_a?(Hash) ? (content[:content] || content.to_s) : content.to_s)
    puts "📄 Saved: #{filepath}"
    filepath
  end
end

# Example usage
begin
  puts "🚀 Starting Advanced Markdown Generation Examples..."
  
  markdown_gen = SuperAgentMarkdownGenerator.new
  
  # Example 1: Technical documentation
  puts "\n🛠️ Example 1: Technical Documentation"
  puts "-" * 35
  
  tech_doc = markdown_gen.generate_technical_documentation("SuperAgent Framework", {
    audience: "Ruby developers",
    include_examples: true
  })
  
  if tech_doc[:success]
    puts "✅ Technical documentation generated"
    puts "📄 File: #{tech_doc[:filename]}"
  else
    puts "❌ Failed: #{tech_doc[:error]}"
  end
  
  # Example 2: Business report
  puts "\n📊 Example 2: Business Report"
  puts "-" * 30
  
  business_data = {
    revenue: 125000,
    users: 1234,
    growth_rate: 15.5,
    top_features: ["AI Integration", "Real-time Updates", "Advanced Analytics"],
    challenges: ["Scale limitations", "API costs"]
  }
  
  report = markdown_gen.generate_business_report(business_data, "Q3 2024 Business Report")
  
  if report[:success]
    puts "✅ Business report generated"
    puts "📄 File: #{report[:filename]}"
  else
    puts "❌ Failed: #{report[:error]}"
  end
  
  # Example 3: API Reference
  puts "\n📚 Example 3: API Reference"
  puts "-" * 25
  
  api_endpoints = [
    { path: "/api/v1/workflows", method: "GET", description: "List all workflows" },
    { path: "/api/v1/workflows", method: "POST", description: "Create new workflow" },
    { path: "/api/v1/workflows/:id", method: "GET", description: "Get workflow details" },
    { path: "/api/v1/workflows/:id/execute", method: "POST", description: "Execute workflow" }
  ]
  
  api_doc = markdown_gen.generate_api_reference("SuperAgent API", api_endpoints)
  
  if api_doc[:success]
    puts "✅ API reference generated"
    puts "📄 File: #{api_doc[:filename]}"
  else
    puts "❌ Failed: #{api_doc[:error]}"
  end
  
  # Example 4: Tutorial
  puts "\n📖 Example 4: Tutorial"
  puts "-" * 20
  
  tutorial = markdown_gen.generate_tutorial("Building AI Workflows with SuperAgent", "intermediate")
  
  if tutorial[:success]
    puts "✅ Tutorial generated"
    puts "📄 File: #{tutorial[:filename]}"
  else
    puts "❌ Failed: #{tutorial[:error]}"
  end
  
  # Example 5: Release Notes
  puts "\n🚀 Example 5: Release Notes"
  puts "-" * 25
  
  changes = [
    "Added vector store support",
    "Enhanced error handling",
    "Improved API documentation",
    "Fixed memory leak in workflow engine",
    "Added support for custom tasks",
    "Updated dependencies for security"
  ]
  
  release_notes = markdown_gen.generate_release_notes("v2.1.0", changes)
  
  if release_notes[:success]
    puts "✅ Release notes generated"
    puts "📄 File: #{release_notes[:filename]}"
  else
    puts "❌ Failed: #{release_notes[:error]}"
  end
  
  # Example 6: Comparison Table
  puts "\n📊 Example 6: Comparison Table"
  puts "-" * 30
  
  items = ["SuperAgent", "LangChain", "LlamaIndex", "Haystack"]
  criteria = ["Ease of Use", "Ruby Integration", "AI Capabilities", "Documentation", "Community"]
  
  comparison = markdown_gen.generate_comparison_table(items, criteria)
  
  if comparison[:success]
    puts "✅ Comparison table generated"
    puts "📄 File: #{comparison[:filename]}"
  else
    puts "❌ Failed: #{comparison[:error]}"
  end
  
  # Example 7: Batch generation
  puts "\n📦 Example 7: Batch Documentation Package"
  puts "-" * 40
  
  package = {
    project_name: "SuperAgent AI Framework",
    components: {
      api_endpoints: [
        { path: "/workflows", method: "GET" },
        { path: "/workflows", method: "POST" },
        { path: "/tasks", method: "GET" }
      ],
      metrics: {
        active_users: 1234,
        api_calls: 45678,
        success_rate: 98.5,
        average_response_time: 245
      },
      version: "2.1.0",
      changes: [
        "New workflow engine",
        "Enhanced security",
        "Improved performance",
        "Better error handling"
      ]
    }
  }
  
  package_result = markdown_gen.create_documentation_package(
    package[:project_name],
    package[:components]
  )
  
  if package_result[:success]
    puts "✅ Documentation package created"
    puts "📦 #{package_result[:successful]}/#{package_result[:total]} files generated"
    puts "📁 Location: ../outputs/markdown/"
  else
    puts "❌ Package failed: #{package_result[:error]}"
  end
  
  # Example 8: Custom template
  puts "\n🎨 Example 8: Custom Template Generation"
  puts "-" * 35
  
  custom_templates = [
    { type: 'technical', title: "Custom Integration Guide", options: { audience: 'system administrators' } },
    { type: 'tutorial', subject: "Advanced Workflow Patterns", level: 'advanced' },
    { type: 'business_report', data: { q4_revenue: 250000, growth: 25.3 }, title: "Q4 Performance Report" }
  ]
  
  batch_result = markdown_gen.batch_generate_documents(custom_templates)
  
  if batch_result[:success]
    puts "✅ Custom templates batch generated"
    puts "📊 #{batch_result[:successful]}/#{batch_result[:total]} successful"
  else
    puts "❌ Batch generation failed: #{batch_result[:error]}"
  end

rescue => e
  puts "❌ Error during markdown generation: #{e.message}"
  puts "🔧 Error details: #{e.backtrace.first(3).join("\n")}"
end

puts "\n" + "=" * 50
puts "🎉 Advanced Markdown Generation Complete!"
puts ""
puts "💡 This example demonstrated:"
puts "   • Technical documentation generation"
puts "   • Business report creation"
puts "   • API reference documentation"
puts "   • Step-by-step tutorials"
puts "   • Release notes creation"
puts "   • Comparison tables"
puts "   • Batch documentation packages"
puts "   • Custom template generation"
puts ""
puts "💰 Estimated cost: ~$0.01-0.10 (per document generation)"
puts "📝 Perfect for: Documentation, reports, tutorials, specifications"