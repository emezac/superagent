#!/usr/bin/env ruby
# frozen_string_literal: true

# ActiveRecord Scope Integration with SuperAgent
# This example demonstrates how to integrate SuperAgent workflows with Rails ActiveRecord
# for intelligent database queries, dynamic filtering, and AI-powered data analysis

require 'bundler/setup'
require 'dotenv'
Dotenv.load('../.env')
require 'super_agent'
require 'date'
require 'json'

puts "🗄️ SuperAgent ActiveRecord Scope Integration"
puts "=" * 55
puts "AI-powered database queries and data analysis"
puts ""

# Configure SuperAgent
SuperAgent.configure do |config|
  config.api_key = ENV['OPENAI_API_KEY'] || 'dummy-key'
  config.logger = Logger.new(STDOUT)
  config.logger.level = Logger::INFO
end

# Mock ActiveRecord models for demonstration
class MockUser
  attr_accessor :id, :name, :email, :role, :created_at, :last_login_at, :status
  
  def initialize(attributes = {})
    @id = attributes[:id]
    @name = attributes[:name]
    @email = attributes[:email]
    @role = attributes[:role]
    @created_at = attributes[:created_at] || Time.now
    @last_login_at = attributes[:last_login_at] || Time.now - (rand(30) * 24 * 60 * 60)
    @status = attributes[:status] || 'active'
  end
  
  def self.all
    [
      MockUser.new(id: 1, name: "Alice Johnson", email: "alice@example.com", role: "admin", status: "active"),
      MockUser.new(id: 2, name: "Bob Smith", email: "bob@company.com", role: "user", status: "active"),
      MockUser.new(id: 3, name: "Charlie Brown", email: "charlie@example.com", role: "moderator", status: "suspended"),
      MockUser.new(id: 4, name: "Diana Prince", email: "diana@company.com", role: "user", status: "active"),
      MockUser.new(id: 5, name: "Eve Wilson", email: "eve@example.com", role: "admin", status: "inactive")
    ]
  end
  
  def self.where(conditions = {})
    all.select do |user|
      conditions.all? { |key, value| user.send(key) == value }
    end
  end
  
  def self.count
    all.length
  end
  
  def self.active
    where(status: 'active')
  end
  
  def self.admin
    where(role: 'admin')
  end
  
  def self.recent(days = 30)
    cutoff = Time.now - (days * 24 * 60 * 60)
    all.select { |user| user.created_at > cutoff }
  end
end

class MockOrder
  attr_accessor :id, :user_id, :total, :status, :created_at, :items_count
  
  def initialize(attributes = {})
    @id = attributes[:id]
    @user_id = attributes[:user_id]
    @total = attributes[:total] || rand(100..1000)
    @status = attributes[:status] || ['pending', 'completed', 'cancelled'].sample
    @created_at = attributes[:created_at] || Time.now - (rand(90) * 24 * 60 * 60)
    @items_count = attributes[:items_count] || rand(1..10)
  end
  
  def self.all
    [
      MockOrder.new(id: 1, user_id: 1, total: 250.50, status: "completed", items_count: 3),
      MockOrder.new(id: 2, user_id: 2, total: 89.99, status: "pending", items_count: 1),
      MockOrder.new(id: 3, user_id: 1, total: 450.00, status: "completed", items_count: 5),
      MockOrder.new(id: 4, user_id: 3, total: 75.25, status: "cancelled", items_count: 2),
      MockOrder.new(id: 5, user_id: 4, total: 1200.00, status: "completed", items_count: 8),
      MockOrder.new(id: 6, user_id: 2, total: 35.00, status: "pending", items_count: 1)
    ]
  end
  
  def self.where(conditions = {})
    all.select do |order|
      conditions.all? { |key, value| order.send(key) == value }
    end
  end
  
  def self.for_user(user_id)
    where(user_id: user_id)
  end
  
  def self.completed
    where(status: 'completed')
  end
  
  def self.high_value(min_amount = 100)
    all.select { |order| order.total >= min_amount }
  end
end

# Define SuperAgent workflows for database operations
class SmartQueryWorkflow < SuperAgent::WorkflowDefinition
  steps do
    step :interpret_query, uses: :llm, with: {
      model: "gpt-4o-mini",
      messages: [
        { role: "system", content: "You are a database query expert. Convert natural language queries into precise ActiveRecord scope queries. Return only the query parameters as JSON." },
        { role: "user", content: "{{natural_language_query}}" }
      ],
      max_tokens: 500
    }
  end
end

class DataAnalysisWorkflow < SuperAgent::WorkflowDefinition
  steps do
    step :analyze_data, uses: :llm, with: {
      model: "gpt-4o-mini",
      messages: [
        { role: "system", content: "You are a data analyst. Analyze the provided dataset and generate insights, trends, and recommendations. Focus on actionable business intelligence." },
        { role: "user", content: "{{data_context}}" }
      ],
      max_tokens: 1000
    }
  end
end

class PredictiveWorkflow < SuperAgent::WorkflowDefinition
  steps do
    step :predict_trends, uses: :llm, with: {
      model: "gpt-4o",
      messages: [
        { role: "system", content: "You are a predictive analytics expert. Based on historical data patterns, predict future trends and provide actionable recommendations." },
        { role: "user", content: "{{prediction_context}}" }
      ],
      max_tokens: 800
    }
  end
end

# SuperAgent Database Intelligence Manager
class DatabaseIntelligenceManager < SuperAgent::Base
  def initialize
    super
    @cache = {}
  end

  def smart_user_query(natural_language)
    puts "🤖 Processing natural language query: '#{natural_language}'"
    
    context = { natural_language_query: natural_language }
    result = run_workflow(SmartQueryWorkflow, initial_input: context)
    
    if result.success?
      query_params = parse_json_response(result.output_for(:interpret_query))
      users = execute_user_query(query_params)
      
      {
        success: true,
        query: natural_language,
        parameters: query_params,
        results: users,
        count: users.length
      }
    else
      { success: false, error: result.error }
    end
  end

  def analyze_user_behavior(user_scope = nil)
    users = user_scope || MockUser.all
    
    data_context = {
      data_context: "Analyze user behavior patterns from this dataset: #{users.map { |u| { id: u.id, name: u.name, role: u.role, status: u.status, created_at: u.created_at } }.to_json}"
    }
    
    result = run_workflow(DataAnalysisWorkflow, initial_input: data_context)
    
    if result.success?
      analysis = result.output_for(:analyze_data)
      {
        success: true,
        analysis: analysis,
        user_count: users.length,
        timestamp: Time.now
      }
    else
      { success: false, error: result.error }
    end
  end

  def predict_user_engagement(user_data)
    prediction_context = {
      prediction_context: "Predict user engagement and retention based on: #{user_data.to_json}"
    }
    
    result = run_workflow(PredictiveWorkflow, initial_input: prediction_context)
    
    if result.success?
      prediction = result.output_for(:predict_trends)
      {
        success: true,
        prediction: prediction,
        confidence: calculate_confidence(user_data),
        recommendations: generate_recommendations(prediction)
      }
    else
      { success: false, error: result.error }
    end
  end

  def dynamic_scope_builder(conditions)
    puts "🔧 Building dynamic scope with conditions: #{conditions}"
    
    case conditions[:type]
    when 'users'
      build_user_scope(conditions)
    when 'orders'
      build_order_scope(conditions)
    else
      { error: "Unknown entity type: #{conditions[:type]}" }
    end
  end

  def complex_query_example
    puts "📊 Executing complex multi-scope query example..."
    
    # Example: Find active users who made high-value orders
    active_users = MockUser.active
    high_value_orders = MockOrder.high_value(100)
    
    # Cross-reference data
    user_orders = active_users.map do |user|
      user_orders = MockOrder.for_user(user.id).select { |o| o.status == 'completed' }
      {
        user: user,
        orders: user_orders,
        total_spent: user_orders.sum(&:total),
        average_order: user_orders.any? ? (user_orders.sum(&:total) / user_orders.length) : 0
      }
    end
    
    # Filter for high-value customers
    valuable_customers = user_orders.select { |data| data[:total_spent] > 200 }
    
    # Generate insights
    insights_context = {
      data_context: "Analyze these valuable customer patterns: #{valuable_customers.to_json}"
    }
    
    result = run_workflow(DataAnalysisWorkflow, initial_input: insights_context)
    
    {
      valuable_customers: valuable_customers,
      insights: result.success? ? result.output_for(:analyze_data) : nil,
      total_revenue: valuable_customers.sum { |c| c[:total_spent] }
    }
  end

  def generate_report(entity_type, scope_conditions = {})
    case entity_type
    when 'users'
      generate_user_report(scope_conditions)
    when 'orders'
      generate_order_report(scope_conditions)
    else
      { error: "Unknown entity type: #{entity_type}" }
    end
  end

  private

  def parse_json_response(response)
    content = response.is_a?(Hash) ? (response[:content] || response.to_s) : response.to_s
    
    # Clean the response by removing markdown code blocks and Ruby code
    content = content.gsub(/```json\n?/, '').gsub(/\n?```/, '').gsub(/\n/, ' ').strip
    
    # Handle Ruby range syntax by extracting simple key-value pairs
    if content.include?('..')
      # Extract the key and fallback to simple approach
      simple_hash = {}
      content.scan(/"(\w+)":\s*"?(\w+)"?/).each do |key, value|
        simple_hash[key] = value
      end
      return simple_hash unless simple_hash.empty?
    end
    
    JSON.parse(content)
  rescue JSON::ParserError
    # Fallback to simple extraction
    simple_hash = {}
    content.scan(/"(\w+)":\s*"?(\w+)"?/).each do |key, value|
      simple_hash[key] = value
    end
    simple_hash.empty? ? {} : simple_hash
  end

  def execute_user_query(params)
    users = MockUser.all
    
    # Apply filters based on AI-generated parameters
    if params['status'] || params[:status]
      status_value = params['status'] || params[:status]
      users = users.select { |u| u.status == status_value }
    end
    
    if params['role'] || params[:role]
      role_value = params['role'] || params[:role]
      users = users.select { |u| u.role == role_value }
    end
    
    if params['created_after'] || params[:created_after]
      cutoff_str = params['created_after'] || params[:created_after]
      begin
        cutoff = Date.parse(cutoff_str)
        users = users.select { |u| u.created_at.to_date > cutoff }
      rescue ArgumentError
        # Handle invalid date format by using 30 days ago as fallback
        cutoff = Date.today - 30
        users = users.select { |u| u.created_at.to_date > cutoff }
      end
    end
    
    users
  end

  def build_user_scope(conditions)
    users = MockUser.all
    
    conditions.each do |key, value|
      case key.to_s
      when 'status'
        users = users.select { |u| u.status == value } if value
      when 'role'
        users = users.select { |u| u.role == value } if value
      when 'recent'
        users = users.recent(value.to_i) if value
      end
    end
    
    {
      entity: 'users',
      results: users,
      count: users.length,
      scope_conditions: conditions
    }
  end

  def build_order_scope(conditions)
    orders = MockOrder.all
    
    conditions.each do |key, value|
      case key.to_s
      when 'status'
        orders = orders.select { |o| o.status == value } if value
      when 'user_id'
        orders = orders.select { |o| o.user_id == value } if value
      when 'min_total'
        orders = orders.select { |o| o.total >= value.to_f }
      end
    end
    
    {
      entity: 'orders',
      results: orders,
      count: orders.length,
      total_value: orders.sum(&:total),
      scope_conditions: conditions
    }
  end

  def calculate_confidence(data)
    # Simple confidence calculation based on data completeness
    return 0.85 if data.is_a?(Hash) && data.keys.length > 3
    0.65
  end

  def generate_recommendations(prediction)
    # Generate actionable recommendations based on prediction
    [
      "Focus on high-value customer retention",
      "Implement targeted marketing campaigns",
      "Monitor user engagement metrics weekly",
      "Consider personalized onboarding for new users"
    ]
  end

  def generate_user_report(conditions)
    users = build_user_scope(conditions)[:results]
    
    stats = {
      total_users: users.length,
      active_users: users.count { |u| u.status == 'active' },
      admin_users: users.count { |u| u.role == 'admin' },
      recent_users: users.count { |u| u.created_at > (Time.now - (30 * 24 * 60 * 60)) }
    }
    
    analysis = analyze_user_behavior(users)
    
    {
      entity: 'users',
      statistics: stats,
      users: users,
      analysis: analysis[:analysis],
      generated_at: Time.now
    }
  end

  def generate_order_report(conditions)
    orders = build_order_scope(conditions)[:results]
    
    stats = {
      total_orders: orders.length,
      total_revenue: orders.sum(&:total),
      completed_orders: orders.count { |o| o.status == 'completed' },
      average_order_value: orders.any? ? (orders.sum(&:total) / orders.length) : 0
    }
    
    {
      entity: 'orders',
      statistics: stats,
      orders: orders,
      generated_at: Time.now
    }
  end
end

# Example usage
begin
  puts "🚀 Starting ActiveRecord Scope Integration Examples..."
  
  db_manager = DatabaseIntelligenceManager.new
  
  # Example 1: Natural language queries
  puts "\n🤖 Example 1: Natural Language Queries"
  puts "-" * 40
  
  queries = [
    "Show me all active users",
    "Find users created in the last 30 days",
    "Get all admin users"
  ]
  
  queries.each do |query|
    puts "\n🔍 Query: '#{query}'"
    result = db_manager.smart_user_query(query)
    
    if result[:success]
      puts "  ✅ Found #{result[:count]} users"
      puts "  📊 Parameters: #{result[:parameters]}"
      result[:results].first(3).each do |user|
        puts "    • #{user.name} (#{user.email}) - #{user.role}"
      end
    else
      puts "  ❌ Error: #{result[:error]}"
    end
  end
  
  # Example 2: Data analysis
  puts "\n📊 Example 2: User Behavior Analysis"
  puts "-" * 35
  
  analysis = db_manager.analyze_user_behavior
  if analysis[:success]
    puts "📈 Analysis Results:"
    analysis_content = analysis[:analysis]
    if analysis_content.is_a?(Hash)
      puts analysis_content[:content] || analysis_content.to_s
    else
      puts analysis_content.to_s
    end
  else
    puts "❌ Analysis failed: #{analysis[:error]}"
  end
  
  # Example 3: Complex query example
  puts "\n🔍 Example 3: Complex Multi-Entity Query"
  puts "-" * 42
  
  complex_result = db_manager.complex_query_example
  puts "💰 Valuable Customers Analysis:"
  puts "  Total customers: #{complex_result[:valuable_customers].length}"
  puts "  Total revenue: $#{complex_result[:total_revenue].round(2)}"
  
  complex_result[:valuable_customers].each do |data|
    puts "    • #{data[:user].name}: $#{data[:total_spent]} (#{data[:orders].length} orders)"
  end
  
  if complex_result[:insights]
    puts "\n💡 AI Insights:"
    insights_content = complex_result[:insights]
    if insights_content.is_a?(Hash)
      puts insights_content[:content] || insights_content.to_s
    else
      puts insights_content.to_s
    end
  end
  
  # Example 4: Dynamic scope building
  puts "\n🏗️ Example 4: Dynamic Scope Building"
  puts "-" * 35
  
  user_scope = db_manager.dynamic_scope_builder({
    type: 'users',
    status: 'active',
    role: 'admin'
  })
  
  puts "Active admin users: #{user_scope[:count]}"
  user_scope[:results].each do |user|
    puts "  • #{user.name} <#{user.email}>"
  end
  
  # Example 5: Predictive analytics
  puts "\n🔮 Example 5: Predictive Analytics"
  puts "-" * 32
  
  user_data = {
    registration_date: Time.now - (15 * 24 * 60 * 60),
    login_frequency: 3.5,
    feature_usage: 0.8,
    support_tickets: 0,
    total_orders: 5,
    average_order: 150.0
  }
  
  prediction = db_manager.predict_user_engagement(user_data)
  if prediction[:success]
    puts "📊 Prediction Results:"
    pred_content = prediction[:prediction]
    if pred_content.is_a?(Hash)
      puts pred_content[:content] || pred_content.to_s
    else
      puts pred_content.to_s
    end
    puts "\n💡 Recommendations:"
    prediction[:recommendations].each { |rec| puts "  • #{rec}" }
  else
    puts "❌ Prediction failed: #{prediction[:error]}"
  end
  
  # Example 6: Generate comprehensive report
  puts "\n📋 Example 6: Comprehensive User Report"
  puts "-" * 38
  
  report = db_manager.generate_report('users', { status: 'active' })
  puts "User Report Summary:"
  puts "  Total users: #{report[:statistics][:total_users]}"
  puts "  Active users: #{report[:statistics][:active_users]}"
  puts "  Recent users: #{report[:statistics][:recent_users]}"
  puts "  Admin users: #{report[:statistics][:admin_users]}"

rescue => e
  puts "❌ Error during database operations: #{e.message}"
  puts "🔧 Error details: #{e.backtrace.first(3).join("\n")}"
end

puts "\n" + "=" * 55
puts "🎉 ActiveRecord Scope Integration Complete!"
puts ""
puts "💡 This example demonstrated:"
puts "   • Natural language database queries"
puts "   • AI-powered data analysis"
puts "   • Predictive analytics with user engagement"
puts "   • Dynamic scope building"
puts "   • Complex multi-entity queries"
puts "   • Comprehensive reporting"
puts ""
puts "💰 Estimated cost: ~$0.01-0.10 (AI analysis queries)"
puts "🗄️ Perfect for: Business intelligence, data dashboards, smart queries"