#!/usr/bin/env ruby
# frozen_string_literal: true

# ActionMailer Integration Example with SuperAgent
# This example demonstrates professional email communication using SuperAgent
# Agents send branded, professional emails using Rails ActionMailer infrastructure

require 'bundler/setup'
require 'dotenv'
Dotenv.load('../.env')
require 'super_agent'
require 'date'

puts "📧 SuperAgent ActionMailer Integration Example"
puts "=" * 65
puts "Professional email communication with SuperAgent workflows"
puts ""

# Configure SuperAgent
SuperAgent.configure do |config|
  config.api_key = ENV['OPENAI_API_KEY'] || 'dummy-key'
  config.logger = Logger.new(STDOUT)
  config.logger.level = Logger::INFO
end

# Mock Rails ActionMailer environment for demonstration
class MockMail
  attr_accessor :to, :from, :subject, :body, :template_name, :layout
  
  def initialize(options = {})
    @to = options[:to]
    @from = options[:from] || 'noreply@company.com'
    @subject = options[:subject]
    @body = options[:body]
    @template_name = options[:template_name]
    @layout = options[:layout] || 'mailer'
    @delivered = false
    @attachments = []
  end

  def deliver_later
    puts "    📤 Email queued for background delivery"
    @delivered = :queued
    self
  end

  def deliver_now
    puts "    📧 Email sent immediately"
    @delivered = :sent
    self
  end

  def delivered?
    @delivered != false
  end

  def attach_file(filename, content_type = nil)
    @attachments << { filename: filename, content_type: content_type }
    puts "    📎 Attachment added: #{filename}"
    self
  end

  def delivery_status
    @delivered
  end

  def to_s
    <<~EMAIL
      From: #{@from}
      To: #{@to}
      Subject: #{@subject}
      Attachments: #{@attachments.length}
      
      #{@body}
    EMAIL
  end
end

# Mock ActionMailer classes for demonstration
class WelcomeMailer
  def self.welcome_email(user_name, user_email)
    MockMail.new(
      to: user_email,
      subject: "Welcome to Our Platform, #{user_name}!",
      body: "Welcome #{user_name}! We're excited to have you on board. Your account has been successfully created and you can start using our services immediately.",
      template_name: 'welcome'
    )
  end
end

class NotificationMailer
  def self.task_completed(user_email, task_name, completion_date)
    MockMail.new(
      to: user_email,
      subject: "Task Completed: #{task_name}",
      body: "Your task '#{task_name}' was completed on #{completion_date}. Great job!",
      template_name: 'task_notification'
    )
  end
end

class ReportMailer
  def self.weekly_report(user_email, report_data)
    report_content = generate_report_content(report_data)
    MockMail.new(
      to: user_email,
      subject: "Weekly Report - #{Date.today.strftime('%B %d, %Y')}",
      body: report_content,
      template_name: 'weekly_report'
    )
  end

  def self.generate_report_content(data)
    <<~REPORT
      Weekly Performance Report
      
      Summary:
      - Total Tasks: #{data[:total_tasks] || 0}
      - Completed: #{data[:completed_tasks] || 0}
      - Pending: #{data[:pending_tasks] || 0}
      - Success Rate: #{data[:success_rate] || 'N/A'}%
      
      Details:
      #{data[:details] || 'No additional details available'}
    REPORT
  end
end

# Define SuperAgent workflows for email management
class EmailGenerationWorkflow < SuperAgent::WorkflowDefinition
  steps do
    step :generate_content, uses: :llm, with: {
      model: "gpt-4o-mini",
      messages: [
        { role: "system", content: "You are a professional email writer. Create engaging, personalized email content based on the provided context and recipient information." },
        { role: "user", content: "{{email_context}}" }
      ],
      max_tokens: 800
    }
  end
end

class EmailPersonalizationWorkflow < SuperAgent::WorkflowDefinition
  steps do
    step :personalize_content, uses: :llm, with: {
      model: "gpt-4o-mini",
      messages: [
        { role: "system", content: "You are an expert at email personalization. Take generic email content and personalize it for the specific recipient, considering their preferences, history, and context." },
        { role: "user", content: "{{personalization_context}}" }
      ],
      max_tokens: 600
    }
  end
end

# Email Campaign Analytics Workflow
class EmailAnalyticsWorkflow < SuperAgent::WorkflowDefinition
  steps do
    step :analyze_performance, uses: :llm, with: {
      model: "gpt-4o-mini",
      messages: [
        { role: "system", content: "You are an email marketing analyst. Analyze email campaign performance data and provide actionable insights and recommendations." },
        { role: "user", content: "{{analytics_data}}" }
      ],
      max_tokens: 1000
    }
  end
end

# SuperAgent Email Manager
class SuperAgentEmailManager < SuperAgent::Base
  def initialize
    super
    @sent_emails = []
  end

  def send_welcome_email(user_name, user_email, options = {})
    puts "📧 Generating welcome email for: #{user_name} (#{user_email})"
    
    # Generate personalized content
    email_context = {
      email_context: "Write a warm, professional welcome email for #{user_name} (#{user_email}). Company: #{options[:company] || 'Our Platform'}. Include onboarding steps and next actions."
    }
    
    result = run_workflow(EmailGenerationWorkflow, initial_input: email_context)
    
    if result.success?
      content = result.output_for(:generate_content)
      email = WelcomeMailer.welcome_email(user_name, user_email)
      email.body = content.is_a?(Hash) ? (content[:content] || content.to_s) : content.to_s
      
      delivery_method = options[:deliver_later] ? :deliver_later : :deliver_now
      email.send(delivery_method)
      
      @sent_emails << {
        type: 'welcome',
        recipient: user_email,
        subject: email.subject,
        delivered: email.delivery_status,
        timestamp: Time.now
      }
      
      { success: true, email: email, content: content }
    else
      { success: false, error: result.error }
    end
  end

  def send_task_notification(user_email, task_name, options = {})
    puts "📧 Sending task completion notification: #{task_name}"
    
    email_context = {
      email_context: "Write a professional task completion notification for task '#{task_name}' sent to #{user_email}. Include completion date: #{options[:completion_date] || Date.today}."
    }
    
    result = run_workflow(EmailGenerationWorkflow, initial_input: email_context)
    
    if result.success?
      content = result.output_for(:generate_content)
      email = NotificationMailer.task_completed(
        user_email, 
        task_name, 
        options[:completion_date] || Date.today
      )
      email.body = content.is_a?(Hash) ? (content[:content] || content.to_s) : content.to_s
      
      email.deliver_now
      
      @sent_emails << {
        type: 'task_notification',
        recipient: user_email,
        subject: email.subject,
        delivered: email.delivery_status,
        timestamp: Time.now
      }
      
      { success: true, email: email }
    else
      { success: false, error: result.error }
    end
  end

  def send_weekly_report(user_email, report_data, options = {})
    puts "📊 Generating weekly report for: #{user_email}"
    
    analytics_context = {
      analytics_data: "Analyze this weekly report data and provide insights: #{report_data.to_json}"
    }
    
    # First generate insights
    insights_result = run_workflow(EmailAnalyticsWorkflow, initial_input: analytics_context)
    
    if insights_result.success?
      insights = insights_result.output_for(:analyze_performance)
      enhanced_report_data = report_data.merge(
        insights: insights.is_a?(Hash) ? (insights[:content] || insights.to_s) : insights.to_s,
        generated_at: Time.now
      )
      
      # Generate personalized report email
      email_context = {
        email_context: "Create a professional weekly report email based on: #{enhanced_report_data.to_json}"
      }
      
      report_result = run_workflow(EmailGenerationWorkflow, initial_input: email_context)
      
      if report_result.success?
        content = report_result.output_for(:generate_content)
        email = ReportMailer.weekly_report(user_email, enhanced_report_data)
        email.body = content.is_a?(Hash) ? (content[:content] || content.to_s) : content.to_s
        
        email.deliver_now
        
        @sent_emails << {
          type: 'weekly_report',
          recipient: user_email,
          subject: email.subject,
          delivered: email.delivery_status,
          timestamp: Time.now,
          attachments: enhanced_report_data[:include_attachments] ? 1 : 0
        }
        
        { success: true, email: email, insights: insights }
      else
        { success: false, error: report_result.error }
      end
    else
      { success: false, error: insights_result.error }
    end
  end

  def send_bulk_campaign(recipients, campaign_data)
    puts "📧 Starting bulk email campaign for #{recipients.length} recipients"
    
    campaign_results = []
    
    recipients.each_with_index do |recipient, index|
      puts "  📤 Processing #{index + 1}/#{recipients.length}: #{recipient[:email]}"
      
      # Personalize email for each recipient
      personalization_context = {
        personalization_context: "Personalize this campaign content: #{campaign_data[:content]} for #{recipient[:name]} with preferences: #{recipient[:preferences].to_json}"
      }
      
      result = run_workflow(EmailPersonalizationWorkflow, initial_input: personalization_context)
      
      if result.success?
        personalized_content = result.output_for(:personalize_content)
        
        # Create and send personalized email
        email = MockMail.new(
          to: recipient[:email],
          subject: campaign_data[:subject],
          body: personalized_content.is_a?(Hash) ? (personalized_content[:content] || personalized_content.to_s) : personalized_content.to_s
        )
        
        email.deliver_later
        
        campaign_results << {
          email: recipient[:email],
          status: 'sent',
          personalized: true
        }
      else
        campaign_results << {
          email: recipient[:email],
          status: 'failed',
          error: result.error
        }
      end
      
      # Add small delay to avoid rate limiting
      sleep(0.5) if index % 5 == 0
    end
    
    {
      success: true,
      total_sent: campaign_results.length,
      successful: campaign_results.count { |r| r[:status] == 'sent' },
      results: campaign_results
    }
  end

  def get_email_history
    @sent_emails
  end

  def get_campaign_stats
    return {} if @sent_emails.empty?
    
    {
      total_emails: @sent_emails.length,
      by_type: @sent_emails.group_by { |e| e[:type] }.transform_values(&:length),
      recent_activity: @sent_emails.last(5),
      success_rate: (@sent_emails.count { |e| e[:delivered] != :failed } * 100.0 / @sent_emails.length).round(2)
    }
  end
end

# Example usage
begin
  puts "🚀 Starting SuperAgent Email Management Examples..."
  
  email_manager = SuperAgentEmailManager.new
  
  # Example 1: Welcome email
  puts "\n📧 Example 1: Welcome Email"
  puts "-" * 30
  welcome_result = email_manager.send_welcome_email(
    "Alice Johnson", 
    "alice@example.com", 
    { company: "TechCorp", deliver_later: false }
  )
  
  if welcome_result[:success]
    puts "✅ Welcome email sent successfully!"
    puts "📨 Email preview:"
    puts welcome_result[:email].to_s
  else
    puts "❌ Failed to send welcome email: #{welcome_result[:error]}"
  end
  
  # Example 2: Task notification
  puts "\n📧 Example 2: Task Completion Notification"
  puts "-" * 40
  notification_result = email_manager.send_task_notification(
    "bob@company.com",
    "Quarterly Financial Report",
    { completion_date: Date.today - 2 }
  )
  
  if notification_result[:success]
    puts "✅ Task notification sent successfully!"
  else
    puts "❌ Failed to send notification: #{notification_result[:error]}"
  end
  
  # Example 3: Weekly report
  puts "\n📊 Example 3: Weekly Report"
  puts "-" * 25
  report_data = {
    total_tasks: 45,
    completed_tasks: 38,
    pending_tasks: 7,
    success_rate: 84.4,
    details: "Major achievements include API integration completion and bug fixes."
  }
  
  report_result = email_manager.send_weekly_report(
    "manager@company.com",
    report_data
  )
  
  if report_result[:success]
    puts "✅ Weekly report sent with insights!"
    puts "💡 Insights: #{report_result[:insights]}" if report_result[:insights]
  else
    puts "❌ Failed to send report: #{report_result[:error]}"
  end
  
  # Example 4: Bulk campaign
  puts "\n📧 Example 4: Bulk Email Campaign"
  puts "-" * 30
  recipients = [
    { name: "Charlie", email: "charlie@example.com", preferences: { industry: "tech" } },
    { name: "Diana", email: "diana@example.com", preferences: { industry: "finance" } },
    { name: "Eve", email: "eve@example.com", preferences: { industry: "healthcare" } }
  ]
  
  campaign_data = {
    subject: "New Feature Launch - Check it out!",
    content: "We're excited to announce our new AI-powered features that will revolutionize your workflow."
  }
  
  campaign_result = email_manager.send_bulk_campaign(recipients, campaign_data)
  
  if campaign_result[:success]
    puts "✅ Bulk campaign completed!"
    puts "📊 Campaign stats:"
    puts "  Total sent: #{campaign_result[:total_sent]}"
    puts "  Successful: #{campaign_result[:successful]}"
  else
    puts "❌ Campaign failed: #{campaign_result[:error]}"
  end
  
  # Display final statistics
  puts "\n📊 Email Campaign Statistics"
  puts "-" * 30
  stats = email_manager.get_campaign_stats
  if stats.any?
    puts "  Total emails: #{stats[:total_emails]}"
    puts "  By type: #{stats[:by_type]}"
    puts "  Success rate: #{stats[:success_rate]}%"
    puts ""
    puts "📋 Recent Activity:"
    stats[:recent_activity].each do |email|
      puts "  #{email[:type]} → #{email[:recipient]} (#{email[:delivered]})"
    end
  end

rescue => e
  puts "❌ Error during email operations: #{e.message}"
  puts "🔧 Error details: #{e.backtrace.first(3).join("\n")}"
end

puts "\n" + "=" * 65
puts "🎉 SuperAgent ActionMailer Integration Complete!"
puts ""
puts "💡 This example demonstrated:"
puts "   • Professional email generation with AI"
puts "   • Personalized content creation"
puts "   • Bulk email campaigns"
puts "   • Campaign analytics and tracking"
puts "   • Multiple email types and templates"
puts "   • Background job integration patterns"
puts ""
puts "💰 Estimated cost: ~$0.01-0.10 (email content generation)"
puts "📧 Perfect for: Marketing automation, user notifications, system alerts"