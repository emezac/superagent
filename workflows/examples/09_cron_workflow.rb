#!/usr/bin/env ruby
# frozen_string_literal: true

# Cron Job Automation with SuperAgent
# This example demonstrates automated scheduling and execution of AI workflows
# using cron-based triggers for periodic tasks like reports, monitoring, and maintenance

require 'bundler/setup'
require 'dotenv'
Dotenv.load('../.env')
require 'super_agent'
require 'date'
require 'json'

puts "⏰ SuperAgent Cron Job Automation"
puts "=" * 45
puts "AI-powered scheduled tasks and automation"
puts ""

# Configure SuperAgent
SuperAgent.configure do |config|
  config.api_key = ENV['OPENAI_API_KEY'] || 'dummy-key'
  config.logger = Logger.new(STDOUT)
  config.logger.level = Logger::INFO
end

# Mock cron job scheduler for demonstration
class CronScheduler
  def self.schedule(cron_expression, task_name, &block)
    puts "📅 Scheduled: #{task_name} (#{cron_expression})"
    { expression: cron_expression, task: task_name, handler: block }
  end

  def self.simulate(cron_jobs)
    puts "\n🎮 Simulating cron job execution..."
    cron_jobs.each do |job|
      puts "\n⚡ Executing: #{job[:task]}"
      job[:handler].call
       sleep(1) # Simulate processing time
    end
  end
end

# Define SuperAgent workflows for different cron tasks
class DailyReportWorkflow < SuperAgent::WorkflowDefinition
  steps do
    step :collect_data, uses: :llm, with: {
      model: "gpt-4o-mini",
      messages: [
        { role: "system", content: "You are a data collector. Gather and summarize daily operational data, including user activity, system performance, and key metrics." },
        { role: "user", content: "Generate daily operational summary for {{report_date}}" }
      ],
      max_tokens: 800
    }
    
    step :generate_report, uses: :markdown, with: {
      content: :report_content,
      title: "Daily Operations Report - {{report_date}}"
    }
  end
end

class WeeklyAnalysisWorkflow < SuperAgent::WorkflowDefinition
  steps do
    step :analyze_trends, uses: :llm, with: {
      model: "gpt-4o",
      messages: [
        { role: "system", content: "You are a business analyst. Analyze weekly trends, identify patterns, and provide strategic recommendations." },
        { role: "user", content: "{{weekly_data}}"}
      ],
      max_tokens: 1200
    }
    
    step :create_summary, uses: :llm, with: {
      model: "gpt-4o-mini",
      messages: [
        { role: "system", content: "Create an executive summary of weekly performance with key insights and next steps." },
        { role: "user", content: "{{analysis_result}}" }
      ],
      max_tokens: 600
    }
  end
end

class MonthlyForecastWorkflow < SuperAgent::WorkflowDefinition
  steps do
    step :forecast_metrics, uses: :llm, with: {
      model: "gpt-4o",
      messages: [
        { role: "system", content: "You are a forecasting expert. Predict next month's metrics based on historical data and current trends." },
        { role: "user", content: "{{historical_data}}" }
      ],
      max_tokens: 1000
    }
    
    step :generate_recommendations, uses: :llm, with: {
      model: "gpt-4o-mini",
      messages: [
        { role: "system", content: "Generate strategic recommendations based on the forecast and current business context." },
        { role: "user", content: "{{forecast_result}}" }
      ],
      max_tokens: 800
    }
  end
end

class HealthCheckWorkflow < SuperAgent::WorkflowDefinition
  steps do
    step :system_check, uses: :llm, with: {
      model: "gpt-4o-mini",
      messages: [
        { role: "system", content: "You are a system health monitor. Check system status, identify potential issues, and provide diagnostic insights." },
        { role: "user", content: "{{system_context}}" }
      ],
      max_tokens: 600
    }
  end
end

class CleanupWorkflow < SuperAgent::WorkflowDefinition
  steps do
    step :identify_cleanup, uses: :llm, with: {
      model: "gpt-4o-mini",
      messages: [
        { role: "system", content: "You are a system maintenance expert. Identify items that need cleanup, optimization, or archiving." },
        { role: "user", content: "{{cleanup_context}}" }
      ],
      max_tokens: 500
    }
  end
end

# SuperAgent Cron Job Manager
class SuperAgentCronManager < SuperAgent::Base
  def initialize
    super
    @job_history = []
    @scheduled_jobs = []
  end

  def schedule_daily_report(time = "09:00")
    puts "📅 Scheduling daily report at #{time}"
    
    CronScheduler.schedule("0 #{time.split(':').first} * * *", "daily_report") do
      execute_daily_report
    end
  end

  def schedule_weekly_analysis(day = "monday", time = "08:00")
    day_num = %w[sunday monday tuesday wednesday thursday friday saturday].index(day.downcase)
    puts "📅 Scheduling weekly analysis every #{day} at #{time}"
    
    CronScheduler.schedule("0 #{time.split(':').first} * * #{day_num}", "weekly_analysis") do
      execute_weekly_analysis
    end
  end

  def schedule_monthly_forecast(day = 1, time = "07:00")
    puts "📅 Scheduling monthly forecast on day #{day} at #{time}"
    
    CronScheduler.schedule("0 #{time.split(':').first} #{day} * *", "monthly_forecast") do
      execute_monthly_forecast
    end
  end

  def schedule_health_check(frequency = "hourly")
    cron_expr = case frequency
                when "hourly" then "0 * * * *"
                when "daily" then "0 12 * * *"
                when "weekly" then "0 12 * * 1"
                end
    
    puts "📅 Scheduling #{frequency} health checks"
    
    CronScheduler.schedule(cron_expr, "health_check") do
      execute_health_check
    end
  end

  def schedule_cleanup(frequency = "daily")
    cron_expr = case frequency
                when "daily" then "0 2 * * *"
                when "weekly" then "0 2 * * 0"
                when "monthly" then "0 2 1 * *"
                end
    
    puts "📅 Scheduling #{frequency} cleanup"
    
    CronScheduler.schedule(cron_expr, "cleanup") do
      execute_cleanup
    end
  end

  def run_immediate(task_name)
    puts "🚀 Running immediate task: #{task_name}"
    
    case task_name
    when 'daily_report'
      execute_daily_report
    when 'weekly_analysis'
      execute_weekly_analysis
    when 'monthly_forecast'
      execute_monthly_forecast
    when 'health_check'
      execute_health_check
    when 'cleanup'
      execute_cleanup
    else
      puts "❌ Unknown task: #{task_name}"
    end
  end

  def simulate_schedule(cron_jobs)
    puts "\n🎮 Simulating scheduled job execution..."
    CronScheduler.simulate(cron_jobs)
  end

  def get_job_history
    @job_history
  end

  def get_performance_metrics
    return {} if @job_history.empty?
    
    {
      total_runs: @job_history.length,
      success_rate: (@job_history.count { |j| j[:status] == 'success' } * 100.0 / @job_history.length).round(2),
      by_task: @job_history.group_by { |j| j[:task] }.transform_values(&:length),
      average_duration: (
        @job_history.sum { |j| j[:duration] || 0 } / @job_history.length.to_f
      ).round(2),
      recent_runs: @job_history.last(5)
    }
  end

  private

  def execute_daily_report
    puts "📊 Generating daily report..."
    start_time = Time.now
    
    context = { 
      report_date: Date.today.to_s,
      report_content: "Daily operations summary for #{Date.today}: System performance, user activity, and key metrics."
    }
    
    result = run_workflow(DailyReportWorkflow, initial_input: context)
    
    duration = Time.now - start_time
    
    if result.success?
      report = result.output_for(:generate_report)
      log_job("daily_report", "success", duration, report)
      puts "✅ Daily report generated successfully"
      puts "📄 Report: #{report[:title]}"
    else
      log_job("daily_report", "failed", duration, { error: result.error })
      puts "❌ Daily report generation failed: #{result.error}"
    end
  end

  def execute_weekly_analysis
    puts "📈 Running weekly analysis..."
    start_time = Time.now
    
    weekly_data = {
      weekly_data: "Weekly performance data: #{generate_mock_weekly_data.to_json}"
    }
    
    result = run_workflow(WeeklyAnalysisWorkflow, initial_input: weekly_data)
    
    duration = Time.now - start_time
    
    if result.success?
      analysis = result.output_for(:analyze_trends)
      summary = result.output_for(:create_summary)
      log_job("weekly_analysis", "success", duration, { analysis: analysis, summary: summary })
      puts "✅ Weekly analysis completed"
      puts "📊 Summary: #{summary.is_a?(Hash) ? (summary[:content] || summary.to_s) : summary}"
    else
      log_job("weekly_analysis", "failed", duration, { error: result.error })
      puts "❌ Weekly analysis failed: #{result.error}"
    end
  end

  def execute_monthly_forecast
    puts "🔮 Generating monthly forecast..."
    start_time = Time.now
    
    historical_data = {
      historical_data: "Historical performance data: #{generate_mock_historical_data.to_json}"
    }
    
    result = run_workflow(MonthlyForecastWorkflow, initial_input: historical_data)
    
    duration = Time.now - start_time
    
    if result.success?
      forecast = result.output_for(:forecast_metrics)
      recommendations = result.output_for(:generate_recommendations)
      log_job("monthly_forecast", "success", duration, { forecast: forecast, recommendations: recommendations })
      puts "✅ Monthly forecast generated"
      puts "🔮 Forecast: #{forecast.is_a?(Hash) ? (forecast[:content] || forecast.to_s) : forecast}"
    else
      log_job("monthly_forecast", "failed", duration, { error: result.error })
      puts "❌ Monthly forecast failed: #{result.error}"
    end
  end

  def execute_health_check
    puts "🏥 Running system health check..."
    start_time = Time.now
    
    system_context = {
      system_context: "Check system health: uptime, performance metrics, error rates, and resource usage"
    }
    
    result = run_workflow(HealthCheckWorkflow, initial_input: system_context)
    
    duration = Time.now - start_time
    
    if result.success?
      health_report = result.output_for(:system_check)
      log_job("health_check", "success", duration, { health_report: health_report })
      puts "✅ Health check completed"
      puts "🏥 Status: #{health_report.is_a?(Hash) ? (health_report[:content] || health_report.to_s) : health_report}"
    else
      log_job("health_check", "failed", duration, { error: result.error })
      puts "❌ Health check failed: #{result.error}"
    end
  end

  def execute_cleanup
    puts "🧹 Running cleanup tasks..."
    start_time = Time.now
    
    cleanup_context = {
      cleanup_context: "Identify temporary files, old logs, expired cache entries, and other cleanup tasks"
    }
    
    result = run_workflow(CleanupWorkflow, initial_input: cleanup_context)
    
    duration = Time.now - start_time
    
    if result.success?
      cleanup_tasks = result.output_for(:identify_cleanup)
      log_job("cleanup", "success", duration, { cleanup_tasks: cleanup_tasks })
      puts "✅ Cleanup tasks identified"
      puts "🧹 Tasks: #{cleanup_tasks.is_a?(Hash) ? (cleanup_tasks[:content] || cleanup_tasks.to_s) : cleanup_tasks}"
    else
      log_job("cleanup", "failed", duration, { error: result.error })
      puts "❌ Cleanup failed: #{result.error}"
    end
  end

  def log_job(task, status, duration, data = {})
    @job_history << {
      task: task,
      status: status,
      duration: duration,
      timestamp: Time.now,
      data: data
    }
  end

  def generate_mock_weekly_data
    {
      users: { new: 45, active: 1234, churned: 12 },
      revenue: { total: 48500, growth: 12.5 },
      performance: { uptime: 99.8, errors: 3 },
      features: { usage: { ai: 234, search: 567, reports: 89 } }
    }
  end

  def generate_mock_historical_data
    {
      months: 6,
      revenue_trend: [42000, 43500, 45000, 46800, 47200, 48500],
      user_growth: [1100, 1120, 1150, 1180, 1210, 1234],
      feature_usage: { ai: [180, 190, 200, 210, 220, 234], search: [500, 520, 530, 540, 555, 567] }
    }
  end
end

# Example usage
begin
  puts "🚀 Starting SuperAgent Cron Job Examples..."
  
  cron_manager = SuperAgentCronManager.new
  
  # Set up scheduled jobs
  puts "📅 Setting up automated schedules..."
  scheduled_jobs = [
    cron_manager.schedule_daily_report("09:00"),
    cron_manager.schedule_weekly_analysis("monday", "08:00"),
    cron_manager.schedule_monthly_forecast(1, "07:00"),
    cron_manager.schedule_health_check("daily"),
    cron_manager.schedule_cleanup("daily")
  ]
  
  puts "\n🎮 Simulating scheduled job execution..."
  cron_manager.simulate_schedule(scheduled_jobs)
  
  # Run immediate examples
  puts "\n⚡ Running immediate task examples..."
  
  immediate_tasks = ['daily_report', 'weekly_analysis', 'health_check']
  immediate_tasks.each do |task|
    puts "\n" + "=" * 45
    cron_manager.run_immediate(task)
  end
  
  # Display performance metrics
  puts "\n📊 Performance Metrics"
  puts "-" * 25
  metrics = cron_manager.get_performance_metrics
  if metrics.any?
    puts "📈 Overall Statistics:"
    puts "  Total runs: #{metrics[:total_runs]}"
    puts "  Success rate: #{metrics[:success_rate]}%"
    puts "  Average duration: #{metrics[:average_duration]}s"
    puts ""
    puts "📋 Recent Job History:"
    metrics[:recent_runs].each do |job|
      puts "  #{job[:task]} → #{job[:status]} (#{job[:duration]}s)"
    end
  end

rescue => e
  puts "❌ Error during cron operations: #{e.message}"
  puts "🔧 Error details: #{e.backtrace.first(3).join("\n")}"
end

puts "\n" + "=" * 45
puts "🎉 SuperAgent Cron Job Automation Complete!"
puts ""
puts "💡 This example demonstrated:"
puts "   • Automated daily reports"
puts "   • Weekly trend analysis"
puts "   • Monthly forecasting"
puts "   • System health monitoring"
puts "   • Automated cleanup tasks"
puts "   • Performance tracking and metrics"
puts ""
puts "💰 Estimated cost: ~$0.01-0.05 (per scheduled task execution)"
puts "⏰ Perfect for: Automated reporting, monitoring, maintenance"