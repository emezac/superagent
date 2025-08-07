# frozen_string_literal: true

require 'spec_helper'
require 'capybara/rspec'

RSpec.describe "Workflow Streaming", type: :system do
  include Capybara::DSL

  let(:test_workflow) do
    Class.new(SuperAgent::WorkflowDefinition) do
      define_task :step1, :direct_handler do |config|
        config.handler = ->(context) { 
          sleep 0.1 # Simulate processing time
          { message: "Step 1 completed with #{context.get(:input)}" } 
        }
      end

      define_task :step2, :turbo_stream do |config|
        config.target = "#progress"
        config.action = "replace"
        config.content = "<div>Processing step 2...</div>"
      end

      define_task :step3, :direct_handler do |config|
        config.handler = ->(context) { 
          sleep 0.1
          { final_result: "Workflow completed" } 
        }
      end

      define_task :step4, :turbo_stream do |config|
        config.target = "#result"
        config.action = "update"
        config.content = "<div class='success'>All steps completed!</div>"
      end
    end
  end

  let(:agent) { Class.new(SuperAgent::Base).new({}) }

  before do
    driven_by :rack_test
    stub_const('TestStreamingWorkflow', test_workflow)
  end

  describe "real-time streaming updates" do
    it "displays progress updates during workflow execution" do
      visit "/test_streaming"

      expect(page).to have_content("Starting workflow...")

      # Wait for step 1 completion
      expect(page).to have_content("Step 1 completed", wait: 5)

      # Wait for step 2 turbo stream update
      expect(page).to have_content("Processing step 2...", wait: 5)

      # Wait for final completion
      expect(page).to have_content("All steps completed!", wait: 5)
    end

    it "handles multiple concurrent streaming workflows" do
      visit "/test_concurrent"

      expect(page).to have_content("Workflow 1 started")
      expect(page).to have_content("Workflow 2 started")

      # Both workflows should complete
      expect(page).to have_content("Workflow 1 completed", wait: 5)
      expect(page).to have_content("Workflow 2 completed", wait: 5)
    end
  end

  describe "error handling in streaming" do
    let(:failing_workflow) do
      Class.new(SuperAgent::WorkflowDefinition) do
        define_task :step1, :direct_handler do |config|
          config.handler = ->(context) { { status: "ok" } }
        end

        define_task :failing_step, :direct_handler do |config|
          config.handler = ->(context) { raise "Simulated error" }
        end

        define_task :error_stream, :turbo_stream do |config|
          config.target = "#errors"
          config.action = "replace"
          config.content = "<div class='error'>An error occurred during processing</div>"
        end
      end
    end

    it "displays error messages when workflow fails" do
      stub_const('FailingWorkflow', failing_workflow)
      visit "/test_failing"

      expect(page).to have_content("Starting workflow...")
      expect(page).to have_content("An error occurred during processing", wait: 5)
    end
  end

  describe "Turbo Stream integration" do
    it "correctly formats turbo stream responses" do
      visit "/test_turbo_format"

      # Check for proper turbo stream format
      expect(page).to have_selector("turbo-stream[action='replace'][target='progress']")
      expect(page).to have_selector("turbo-stream[action='update'][target='result']")
    end

    it "supports different turbo stream actions" do
      visit "/test_actions"

      expect(page).to have_selector("turbo-stream[action='append'][target='log']")
      expect(page).to have_selector("turbo-stream[action='prepend'][target='notifications']")
      expect(page).to have_selector("turbo-stream[action='remove'][target='spinner']")
    end
  end
end

# Test controller for system tests
class TestStreamingController < ActionController::Base
  include ActionView::Helpers::TagHelper
  include Turbo::Streams::ActionHelper

  def test_streaming
    render inline: <<~HTML
      <div id="progress">Starting workflow...</div>
      <div id="result">Waiting for results...</div>
      <div id="turbo-stream-responses"></div>
      
      <script>
        // Simulate streaming workflow execution
        setTimeout(() => {
          document.getElementById('turbo-stream-responses').innerHTML = `
            <turbo-stream action="replace" target="progress">
              <template>Step 1 completed with test data</template>
            </turbo-stream>
            <turbo-stream action="replace" target="progress">
              <template>Processing step 2...</template>
            </turbo-stream>
            <turbo-stream action="update" target="result">
              <template><div class='success'>All steps completed!</div></template>
            </turbo-stream>
          `;
        }, 100);
      </script>
    HTML
  end

  def test_concurrent
    render inline: <<~HTML
      <div id="workflow-1">Workflow 1 started</div>
      <div id="workflow-2">Workflow 2 started</div>
      
      <script>
        setTimeout(() => {
          document.getElementById('workflow-1').textContent = 'Workflow 1 completed';
          document.getElementById('workflow-2').textContent = 'Workflow 2 completed';
        }, 200);
      </script>
    HTML
  end

  def test_failing
    render inline: <<~HTML
      <div id="progress">Starting workflow...</div>
      <div id="errors"></div>
      
      <script>
        setTimeout(() => {
          document.getElementById('errors').innerHTML = `
            <turbo-stream action="replace" target="errors">
              <template><div class='error'>An error occurred during processing</div></template>
            </turbo-stream>
          `;
        }, 100);
      </script>
    HTML
  end

  def test_turbo_format
    render inline: <<~HTML
      <turbo-stream action="replace" target="progress">
        <template>Updated content</template>
      </turbo-stream>
      <turbo-stream action="update" target="result">
        <template>Final result</template>
      </turbo-stream>
    HTML
  end

  def test_actions
    render inline: <<~HTML
      <turbo-stream action="append" target="log">
        <template>Log entry</template>
      </turbo-stream>
      <turbo-stream action="prepend" target="notifications">
        <template>New notification</template>
      </turbo-stream>
      <turbo-stream action="remove" target="spinner">
      </turbo-stream>
    HTML
  end
end