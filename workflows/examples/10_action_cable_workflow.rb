#!/usr/bin/env ruby
# frozen_string_literal: true

# ActionCable Integration with SuperAgent
# This example demonstrates real-time WebSocket communication using ActionCable
# with AI-powered message handling, broadcast management, and live updates

require 'bundler/setup'
require 'dotenv'
Dotenv.load('../.env')
require 'super_agent'
require 'json'

puts "📡 SuperAgent ActionCable Integration"
puts "=" * 48
puts "Real-time AI-powered WebSocket communication"
puts ""

# Configure SuperAgent
SuperAgent.configure do |config|
  config.api_key = ENV['OPENAI_API_KEY'] || 'dummy-key'
  config.logger = Logger.new(STDOUT)
  config.logger.level = Logger::INFO
end

# Mock ActionCable components for demonstration
class MockChannel
  attr_reader :name, :subscribers, :messages
  
  def initialize(name)
    @name = name
    @subscribers = []
    @messages = []
    @message_handlers = {}
  end
  
  def subscribe(connection_id)
    @subscribers << connection_id unless @subscribers.include?(connection_id)
    puts "👤 #{connection_id} subscribed to #{@name}"
    { status: 'subscribed', channel: @name }
  end
  
  def unsubscribe(connection_id)
    @subscribers.delete(connection_id)
    puts "👤 #{connection_id} unsubscribed from #{@name}"
    { status: 'unsubscribed', channel: @name }
  end
  
  def broadcast(message, sender = nil)
    @messages << { message: message, sender: sender, timestamp: Time.now }
    puts "📡 Broadcasting to #{@subscribers.length} subscribers: #{message}"
    
    # Simulate sending to all subscribers
    @subscribers.each do |subscriber|
      puts "  → Sent to: #{subscriber}"
    end
    
    { status: 'broadcast', recipients: @subscribers.length }
  end
  
  def stream_from(stream_name)
    puts "📺 Streaming from: #{stream_name}"
    { status: 'streaming', stream: stream_name }
  end
  
  def handle_message(message, connection_id)
    handler = @message_handlers[message[:type]]
    handler ? handler.call(message, connection_id) : { status: 'unknown_type' }
  end
  
  def on_message(type, &handler)
    @message_handlers[type] = handler
  end
end

class MockConnection
  attr_reader :id, :channels, :subscriptions
  
  def initialize(id)
    @id = id
    @channels = {}
    @subscriptions = []
  end
  
  def subscribe_to(channel_name)
    channel = MockChannel.new(channel_name)
    @channels[channel_name] = channel
    @subscriptions << channel_name
    channel.subscribe(@id)
  end
  
  def send_message(channel_name, message)
    return unless @channels[channel_name]
    @channels[channel_name].broadcast(message, @id)
  end
end

# Define SuperAgent workflows for real-time processing
class MessageProcessingWorkflow < SuperAgent::WorkflowDefinition
  steps do
    step :process_message, uses: :llm, with: {
      model: "gpt-4o-mini",
      messages: [
        { role: "system", content: "You are a real-time message processor. Analyze incoming messages and generate appropriate responses or actions." },
        { role: "user", content: "{{message_content}}" }
      ],
      max_tokens: 400
    }
  end
end

class NotificationWorkflow < SuperAgent::WorkflowDefinition
  steps do
    step :generate_notification, uses: :llm, with: {
      model: "gpt-4o-mini",
      messages: [
        { role: "system", content: "You are a notification generator. Create personalized, relevant notifications based on user actions and system events." },
        { role: "user", content: "{{notification_context}}" }
      ],
      max_tokens: 300
    }
  end
end

class ChatSummaryWorkflow < SuperAgent::WorkflowDefinition
  steps do
    step :summarize_chat, uses: :llm, with: {
      model: "gpt-4o-mini",
      messages: [
        { role: "system", content: "You are a chat summarizer. Create concise summaries of conversation threads, highlighting key points and decisions." },
        { role: "user", content: "{{chat_history}}" }
      ],
      max_tokens: 400
    }
  end
end

class ContentModerationWorkflow < SuperAgent::WorkflowDefinition
  steps do
    step :moderate_content, uses: :llm, with: {
      model: "gpt-4o-mini",
      messages: [
        { role: "system", content: "You are a content moderator. Review messages for appropriateness, policy violations, and sentiment. Provide moderation recommendations." },
        { role: "user", content: "{{content_to_moderate}}" }
      ],
      max_tokens: 200
    }
  end
end

# SuperAgent Real-Time Manager
class SuperAgentRealTimeManager < SuperAgent::Base
  def initialize
    super
    @channels = {}
    @connections = {}
    @message_history = []
  end

  def create_channel(name)
    @channels[name] = MockChannel.new(name)
    puts "✅ Created channel: #{name}"
    @channels[name]
  end

  def create_connection(connection_id)
    @connections[connection_id] = MockConnection.new(connection_id)
    puts "✅ Created connection: #{connection_id}"
    @connections[connection_id]
  end

  def subscribe_to_channel(connection_id, channel_name)
    connection = @connections[connection_id]
    channel = @channels[channel_name]
    
    return { error: "Connection or channel not found" } unless connection && channel
    
    connection.subscribe_to(channel_name)
    { status: 'subscribed', connection: connection_id, channel: channel_name }
  end

  def send_message(connection_id, channel_name, message)
    connection = @connections[connection_id]
    channel = @channels[channel_name]
    
    return { error: "Connection or channel not found" } unless connection && channel
    
    # Process message with AI
    processed_message = process_realtime_message(message, connection_id)
    
    # Broadcast to channel
    broadcast_result = channel.broadcast(processed_message, connection_id)
    
    # Store in history
    @message_history << {
      connection_id: connection_id,
      channel: channel_name,
      message: processed_message,
      timestamp: Time.now
    }
    
    { status: 'sent', processed_message: processed_message, broadcast: broadcast_result }
  end

  def handle_system_event(event_type, data)
    puts "🔔 Processing system event: #{event_type}"
    
    case event_type
    when 'user_joined'
      handle_user_joined(data)
    when 'order_completed'
      handle_order_completed(data)
    when 'alert_triggered'
      handle_alert_triggered(data)
    else
      { error: "Unknown event type: #{event_type}" }
    end
  end

  def moderate_channel_content(channel_name, content)
    channel = @channels[channel_name]
    return { error: "Channel not found" } unless channel
    
    context = { content_to_moderate: content }
    result = run_workflow(ContentModerationWorkflow, initial_input: context)
    
    if result.success?
      moderation = result.output_for(:moderate_content)
      { status: 'moderated', result: moderation }
    else
      { error: result.error }
    end
  end

  def generate_chat_summary(channel_name)
    channel = @channels[channel_name]
    return { error: "Channel not found" } unless channel
    
    chat_history = @message_history.select { |msg| msg[:channel] == channel_name }
    return { error: "No messages found" } if chat_history.empty?
    
    context = { 
      chat_history: chat_history.map { |msg| "#{msg[:connection_id]}: #{msg[:message]}" }.join("\n") 
    }
    
    result = run_workflow(ChatSummaryWorkflow, initial_input: context)
    
    if result.success?
      summary = result.output_for(:summarize_chat)
      { status: 'summarized', summary: summary }
    else
      { error: result.error }
    end
  end

  def broadcast_to_all(message)
    results = {}
    @channels.each do |name, channel|
      results[name] = channel.broadcast(message, "system")
    end
    results
  end

  def get_channel_stats(channel_name)
    channel = @channels[channel_name]
    return { error: "Channel not found" } unless channel
    
    {
      name: channel_name,
      subscribers: channel.subscribers.length,
      messages_count: channel.messages.length,
      last_activity: channel.messages.any? ? channel.messages.last[:timestamp] : nil
    }
  end

  def get_connection_stats(connection_id)
    connection = @connections[connection_id]
    return { error: "Connection not found" } unless connection
    
    {
      connection_id: connection_id,
      subscriptions: connection.subscriptions,
      active_channels: connection.channels.length
    }
  end

  def setup_channel_handlers(channel_name)
    channel = @channels[channel_name]
    return unless channel
    
    # Setup message handlers for different message types
    channel.on_message("chat") do |message, connection_id|
      { type: "chat", response: "Chat message processed", original: message }
    end
    
    channel.on_message("query") do |message, connection_id|
      ai_response = process_realtime_query(message[:query])
      { type: "query_response", response: ai_response, original: message }
    end
    
    channel.on_message("notification") do |message, connection_id|
      notification = generate_realtime_notification(message)
      { type: "notification", response: notification, original: message }
    end
  end

  private

  def process_realtime_message(message, connection_id)
    context = { 
      message_content: "Process this real-time message: #{message} from connection #{connection_id}"
    }
    
    result = run_workflow(MessageProcessingWorkflow, initial_input: context)
    
    if result.success?
      processed = result.output_for(:process_message)
      processed.is_a?(Hash) ? (processed[:content] || processed.to_s) : processed.to_s
    else
      "Error processing message: #{result.error}"
    end
  end

  def process_realtime_query(query)
    context = { 
      message_content: "Answer this real-time query: #{query}"
    }
    
    result = run_workflow(MessageProcessingWorkflow, initial_input: context)
    
    if result.success?
      response = result.output_for(:process_message)
      response.is_a?(Hash) ? (response[:content] || response.to_s) : response.to_s
    else
      "Unable to process query"
    end
  end

  def generate_realtime_notification(data)
    context = { 
      notification_context: "Generate notification for: #{data.to_json}"
    }
    
    result = run_workflow(NotificationWorkflow, initial_input: context)
    
    if result.success?
      notification = result.output_for(:generate_notification)
      notification.is_a?(Hash) ? (notification[:content] || notification.to_s) : notification.to_s
    else
      "System notification"
    end
  end

  def handle_user_joined(data)
    channel = @channels["general"]
    return { error: "General channel not found" } unless channel
    
    welcome_message = generate_realtime_notification({
      type: "user_joined",
      user: data[:user_name],
      timestamp: Time.now
    })
    
    channel.broadcast(welcome_message, "system")
    { status: "welcome_sent", user: data[:user_name] }
  end

  def handle_order_completed(data)
    channel = @channels["orders"]
    return { error: "Orders channel not found" } unless channel
    
    notification = generate_realtime_notification({
      type: "order_completed",
      order_id: data[:order_id],
      amount: data[:amount],
      user: data[:user_name]
    })
    
    channel.broadcast(notification, "system")
    { status: "notification_sent", order: data[:order_id] }
  end

  def handle_alert_triggered(data)
    channel = @channels["alerts"]
    return { error: "Alerts channel not found" } unless channel
    
    alert_message = generate_realtime_notification({
      type: "alert",
      severity: data[:severity],
      message: data[:message],
      timestamp: Time.now
    })
    
    channel.broadcast(alert_message, "system")
    { status: "alert_sent", severity: data[:severity] }
  end
end

# Example usage
begin
  puts "🚀 Starting SuperAgent ActionCable Examples..."
  
  realtime_manager = SuperAgentRealTimeManager.new
  
  # Setup channels
  puts "\n📡 Setting up channels..."
  general_channel = realtime_manager.create_channel("general")
  orders_channel = realtime_manager.create_channel("orders")
  alerts_channel = realtime_manager.create_channel("alerts")
  
  # Setup handlers
  ["general", "orders", "alerts"].each do |channel_name|
    realtime_manager.setup_channel_handlers(channel_name)
  end
  
  # Create connections
  puts "\n🔌 Creating connections..."
  alice = realtime_manager.create_connection("alice_user_123")
  bob = realtime_manager.create_connection("bob_user_456")
  charlie = realtime_manager.create_connection("charlie_admin_789")
  
  # Subscribe to channels
  puts "\n👥 Subscribing to channels..."
  realtime_manager.subscribe_to_channel("alice_user_123", "general")
  realtime_manager.subscribe_to_channel("bob_user_456", "general")
  realtime_manager.subscribe_to_channel("charlie_admin_789", "alerts")
  
  # Example 1: Chat messages
  puts "\n💬 Example 1: Real-time Chat Messages"
  puts "-" * 35
  
  messages = [
    { from: "alice_user_123", to: "general", message: "Hello everyone! How's the new feature working?" },
    { from: "bob_user_456", to: "general", message: "Hey Alice! The AI integration is amazing!" },
    { from: "alice_user_123", to: "general", message: "Great to hear! What's your favorite part?" }
  ]
  
  messages.each do |msg|
    result = realtime_manager.send_message(msg[:from], msg[:to], msg[:message])
    if result[:status] == 'sent'
      puts "✅ Message sent: #{result[:processed_message]}"
    else
      puts "❌ Failed to send: #{result[:error]}"
    end
  end
  
  # Example 2: System events
  puts "\n🔔 Example 2: System Events"
  puts "-" * 25
  
  events = [
    { type: 'user_joined', user_name: 'David', email: 'david@example.com' },
    { type: 'order_completed', order_id: 12345, amount: 299.99, user_name: 'Alice' },
    { type: 'alert_triggered', severity: 'medium', message: 'High server load detected' }
  ]
  
  events.each do |event|
    result = realtime_manager.handle_system_event(event[:type], event)
    if result[:status]
      puts "✅ Event processed: #{event[:type]}"
    else
      puts "❌ Event failed: #{result[:error]}"
    end
  end
  
  # Example 3: Content moderation
  puts "\n🛡️ Example 3: Content Moderation"
  puts "-" * 30
  
  content_samples = [
    "This is a great product!",
    "I need help with the setup process",
    "Check out this amazing deal!"
  ]
  
  content_samples.each do |content|
    result = realtime_manager.moderate_channel_content("general", content)
    if result[:status] == 'moderated'
      moderation_result = result[:result]
      moderation_text = moderation_result.is_a?(Hash) ? (moderation_result[:content] || moderation_result.to_s) : moderation_result.to_s
      puts "✅ Content \"#{content}\" - Moderation: #{moderation_text}"
    else
      puts "❌ Moderation failed: #{result[:error]}"
    end
  end
  
  # Example 4: Chat summary
  puts "\n📝 Example 4: Chat Summary"
  puts "-" * 25
  
  summary = realtime_manager.generate_chat_summary("general")
  if summary[:status] == 'summarized'
    puts "✅ Chat Summary:"
    puts summary[:summary].is_a?(Hash) ? (summary[:summary][:content] || summary[:summary].to_s) : summary[:summary].to_s
  else
    puts "❌ Summary failed: #{summary[:error]}"
  end
  
  # Example 5: Channel statistics
  puts "\n📊 Example 5: Channel Statistics"
  puts "-" * 30
  
  ["general", "orders", "alerts"].each do |channel_name|
    stats = realtime_manager.get_channel_stats(channel_name)
    puts "📈 #{channel_name.capitalize}:"
    puts "  Subscribers: #{stats[:subscribers]}"
    puts "  Messages: #{stats[:messages_count]}"
    puts "  Last activity: #{stats[:last_activity]}"
    puts ""
  end
  
  # Example 6: Broadcast to all
  puts "📢 Example 6: System-wide Broadcast"
  puts "-" * 35
  
  system_message = "🎉 System maintenance completed successfully! All services are running normally."
  results = realtime_manager.broadcast_to_all(system_message)
  
  puts "✅ System message broadcast to #{results.keys.length} channels"
  results.each do |channel, result|
    puts "  📡 #{channel}: #{result[:recipients]} subscribers"
  end

rescue => e
  puts "❌ Error during real-time operations: #{e.message}"
  puts "🔧 Error details: #{e.backtrace.first(3).join("\n")}"
end

puts "\n" + "=" * 48
puts "🎉 SuperAgent ActionCable Integration Complete!"
puts ""
puts "💡 This example demonstrated:"
puts "   • Real-time WebSocket communication"
puts "   • AI-powered message processing"
puts "   • Content moderation"
puts "   • System event handling"
puts "   • Chat summarization"
puts "   • Broadcast management"
puts ""
puts "💰 Estimated cost: ~$0.01-0.05 (real-time processing)"
puts "📡 Perfect for: Live chat, real-time updates, notifications"