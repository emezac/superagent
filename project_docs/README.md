# SuperAgent

A next-generation Ruby on Rails framework for building AI-powered SaaS applications. SuperAgent unifies AI workflow orchestration with Rails-native MVC interactions to create truly agentic applications that go beyond simple chatbots.

## What is SuperAgent?

SuperAgent is a Rails framework that combines:
- **AI Workflow Orchestration**: Complex, multi-step AI processes with built-in observability
- **Rails-Native Interactions**: Seamless integration with Rails controllers, views, and Turbo
- **Agentic Architecture**: Applications that reason, act, and collaborate as intelligent teammates

Instead of building chatbots, you're building applications where AI agents proactively manage business processes, make decisions, and interact with users through familiar Rails patterns.

## Key Features

- **Workflow Engine**: Orchestrate complex AI tasks with retry logic, error handling, and real-time progress
- **Streaming Updates**: Live progress updates via Turbo Streams for long-running AI processes
- **Async Execution**: Background processing with ActiveJob integration
- **Security First**: Built-in sensitive data filtering and authorization
- **Rails Native**: Works seamlessly with Devise, Pundit, ActiveRecord, and Turbo
- **Observability**: Structured logging with workflow execution tracing

## Quick Example

```ruby
# app/agents/lead_analysis_agent.rb
class LeadAnalysisAgent < SuperAgent::Base
  def analyze_leads(leads)
    run_workflow(LeadAnalysisWorkflow, initial_input: { leads: leads }) do |step|
      stream_update(partial: "leads/progress", locals: { step: step })
    end

    if result.completed?
      prompt(message: "Analysis complete", details: result.final_output)
    else
      prompt(alert: "Failed at step: #{result.failed_task_name}")
    end
  end
end

# app/workflows/lead_analysis_workflow.rb
class LeadAnalysisWorkflow < SuperAgent::Workflow
  steps do
    step :authorize, uses: :pundit_policy, with: { action: :analyze }
    step :enrich, uses: :direct_handler, with: ->(context) { LeadEnricher.call(context.leads) }
    step :score, uses: :llm_task, with: { prompt: "Score these leads...", model: "gpt-4" }
    step :notify, uses: :action_mailer, with: { mailer: 'LeadMailer', action: 'analysis_complete' }
  end
end
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

## Getting Started

1. **Generate your first agent:**
   ```bash
   rails generate super_agent:resource LeadAnalysis --actions=analyze,prioritize
   ```

2. **Define workflows** in `app/workflows/`
3. **Call agents** from your controllers or Turbo streams
4. **Stream progress** to your users in real-time

## Documentation

- [Installation Guide](docs/installation.md)
- [Workflow Engine](docs/workflows.md)
- [Agent Development](docs/agents.md)
- [Real-time Streaming](docs/streaming.md)
- [Security Best Practices](docs/security.md)

## Use Cases

SuperAgent excels at:
- **CRM Intelligence**: Automated lead scoring and customer insights
- **Compliance Automation**: Regulatory monitoring and reporting
- **Content Management**: Brand-consistent content generation and approval
- **E-commerce**: Dynamic pricing and inventory optimization
- **DevOps**: Automated testing and deployment workflows

## Architecture

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Agent Action  │───▶│  Workflow Engine │───▶│     Tasks       │
│   (Controller)  │    │   (Orchestrator) │    │ (LLM, DB, API)  │
└─────────────────┘    └──────────────────┘    └─────────────────┘
         │                       │                       │
         ▼                       ▼                       ▼
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│ Turbo Streams   │    │  Context Object  │    │   Logging       │
│   (Real-time)   │    │   (State Mgmt)   │    │ (Observability) │
└─────────────────┘    └──────────────────┘    └─────────────────┘
```

## Contributing

This is pre-release software. We're building SuperAgent in the open. Check the [roadmap](TODO_LIST.md) and [issues](https://github.com/your-org/superagent/issues) to get involved.

## License

MIT License - see [LICENSE](LICENSE) for details.
