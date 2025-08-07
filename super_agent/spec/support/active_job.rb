# frozen_string_literal: true

# Configure ActiveJob for testing
ActiveJob::Base.queue_adapter = :test

RSpec.configure do |config|
  config.include ActiveJob::TestHelper

  config.before(:each) do
    clear_enqueued_jobs
    clear_performed_jobs
  end

  # Helper for testing async workflows
  config.include Module.new {
    def with_async_workflow_testing
      original_adapter = ActiveJob::Base.queue_adapter
      ActiveJob::Base.queue_adapter = :test
      
      yield
    ensure
      ActiveJob::Base.queue_adapter = original_adapter
    end
  }
end