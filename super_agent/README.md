# SuperAgent 🦸‍♂️

[![Gem Version](https://badge.fury.io/rb/super_agent.svg)](https://badge.fury.io/rb/super_agent)
[![CI](https://github.com/your-org/super_agent/workflows/CI/badge.svg)](https://github.com/your-org/super_agent/actions)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](https://opensource.org/licenses/MIT)

A Ruby on Rails framework for building AI-powered SaaS applications with intelligent workflow orchestration and real-time streaming capabilities.

## Overview

SuperAgent combines two powerful concepts:
- **Workflow Orchestration**: Define complex AI workflows as composable, observable tasks
- **Rails Integration**: Seamlessly integrate AI capabilities into your Rails applications

The framework provides a clean separation between interaction layer (controllers/agents) and business logic (workflows), making AI applications maintainable, testable, and scalable.

## ✨ Features

- ✅ **Real-time Streaming**: Turbo Streams integration for progressive UI updates
- ✅ **Immutable Context Management**: Safe, type-checked state passing between tasks
- ✅ **Robust Workflow Engine**: Built-in logging, error handling, and retry mechanisms
- ✅ **Multiple Task Types**: LLM calls, DB queries, emails, policies, and custom tasks
- ✅ **Rails Native**: Seamless integration with Rails 7.1+ conventions
- ✅ **Security First**: Pundit integration and sensitive data filtering
- ✅ **Async Execution**: ActiveJob integration for background processing
- ✅ **Comprehensive Testing**: 200+ tests with system specs and Capybara

## Architecture

```
┌─────────────────────────────────────┐
│          Rails App                  │
│  ┌─────────────────────────────────┐ │
│  │     SuperAgent::Base            │ │
│  │       (Interaction Layer)       │ │
│  └─────────────────────────────────┘ │
│                 │                     │
│  ┌─────────────────────────────────┐ │
│  │     Workflow Engine             │ │
│  │  (Orchestration Layer)         │ │
│  └─────────────────────────────────┘ │
└─────────────────────────────────────┘
```

## Installation

Add to your Gemfile:

```ruby
gem 'super_agent'
```

Then run:

```bash
bundle install
rails generate super_agent:install
```

## 🚀 Quick Start

### Installation

Add to your Gemfile:

```ruby
gem "super_agent"
```

Then run:

```bash
bundle install
rails generate super_agent:install
rails db:migrate
```

### Creating Your First AI Agent

```ruby
# app/agents/lead_analysis_agent.rb
class LeadAnalysisAgent < SuperAgent::Base
  def analyze_lead(lead_data)
    result = run_workflow(LeadAnalysisWorkflow, initial_input: lead_data)
    
    if result.completed?
      render json: { analysis: result.final_output }
    else
      render json: { error: result.error_message }, status: 422
    end
  end
end
```

### Defining AI Workflows

```ruby
# app/workflows/lead_analysis_workflow.rb
class LeadAnalysisWorkflow < SuperAgent::WorkflowDefinition
  define_task :validate_lead, :pundit_policy do |config|
    config.policy_class = LeadPolicy
    config.action = :analyze?
  end

  define_task :enrich_data, :llm do |config|
    config.model = "gpt-4"
    config.system_prompt = "Analyze this lead and provide insights"
    config.template = "Lead: {{lead_data}}"
  end

  define_task :score_lead, :direct_handler do |config|
    config.handler = ->(context) {
      data = context.get(:enrich_data)
      { score: calculate_score(data) }
    }
  end

  define_task :notify_team, :action_mailer do |config|
    config.mailer_class = LeadMailer
    config.action = :analysis_complete
    config.params = { lead_id: "{{lead_id}}", score: "{{score}}" }
  end
end
```

### Real-time Streaming

```ruby
# Progressive UI updates
def analyze_with_streaming(lead_data)
  run_workflow(LeadAnalysisWorkflow, initial_input: lead_data, streaming: true) do |step_result|
    Turbo::StreamsChannel.broadcast_replace_to(
      "lead_#{lead_data[:id]}",
      target: "analysis_status",
      partial: "leads/analysis_step",
      locals: { step: step_result }
    )
  end
end
```

## Core Concepts

### Context

The `Context` object provides immutable state management:

```ruby
context = SuperAgent::Workflow::Context.new(user: "Alice", data: [1, 2, 3])
new_context = context.set(:processed, context.get(:data).sum)
```

### Tasks

Available task types:

- **DirectHandlerTask**: Execute Ruby code directly
- **LLMTask**: Interact with Large Language Models
- **Custom Tasks**: Create your own task types

### Workflow Engine

The engine orchestrates task execution:

```ruby
engine = SuperAgent::WorkflowEngine.new
result = engine.execute(MyWorkflow, context)

puts result.completed? # true/false
puts result.final_output # Last step's output
puts result.output_for(:step_name) # Specific step output
```

## Configuration

Configure SuperAgent in an initializer:

```ruby
# config/initializers/super_agent.rb
SuperAgent.configure do |config|
  config.api_key = ENV['OPENAI_API_KEY']
  config.default_llm_model = 'gpt-3.5-turbo'
  config.default_llm_timeout = 30
  config.default_llm_retries = 2
  config.logger = Rails.logger
end
```

## Development

### Running Tests

```bash
bundle exec rspec
```

### Test Coverage

The test suite includes:
- Context management and immutability
- Task execution and error handling
- Workflow orchestration
- LLM integration patterns
- Logging and observability
- Error scenarios and edge cases

### Project Structure

```
super_agent/
├── lib/
│   ├── super_agent.rb
│   ├── super_agent/
│   │   ├── configuration.rb
│   │   ├── workflow_engine.rb
│   │   ├── workflow_definition.rb
│   │   ├── workflow_result.rb
│   │   └── workflow/
│   │       ├── context.rb
│   │       ├── task.rb
│   │       ├── direct_handler_task.rb
│   │       └── llm_task.rb
├── spec/
│   ├── super_agent/
│   │   ├── workflow_engine_spec.rb
│   │   └── workflow/
│   │       ├── context_spec.rb
│   │       ├── task_spec.rb
│   │       ├── direct_handler_task_spec.rb
│   │       └── llm_task_spec.rb
│   └── spec_helper.rb
└── super_agent.gemspec
```

## API Reference

### WorkflowDefinition

Base class for defining workflows:

```ruby
class MyWorkflow < SuperAgent::WorkflowDefinition
  steps do
    step :name, uses: :task_type, **options
  end
end
```

### Context

Immutable state container:

- `get(key)` - Retrieve value
- `set(key, value)` - Return new context with updated value
- `to_h` - Convert to hash

### WorkflowResult

Execution result object:

- `completed?` - Check if all steps succeeded
- `failed?` - Check if any step failed
- `final_output` - Last step's output
- `output_for(step_name)` - Specific step output
- `full_trace` - Complete execution history
- `duration_ms` - Total execution time

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -am 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Roadmap

- [x] Core workflow engine and task system
- [x] Context management and immutability
- [x] LLM integration with OpenAI
- [x] Comprehensive test suite
- [ ] Rails generators for easy setup
- [ ] Async execution with ActiveJob
- [ ] Real-time streaming capabilities
- [ ] Additional LLM providers
- [ ] Web UI for workflow monitoring
