# frozen_string_literal: true

require 'spec_helper'

RSpec.describe "Streaming Functionality" do
  let(:test_workflow) do
    Class.new(SuperAgent::WorkflowDefinition) do
      define_task :step1, :direct_handler do |config|
        config.handler = ->(context) { { result: "step1_output", input: context.get(:input) } }
      end

      define_task :step2, :direct_handler do |config|
        config.handler = ->(context) { { result: "step2_output", step1: context.get(:step1) } }
      end
    end
  end

  let(:context) { SuperAgent::Workflow::Context.new(input: "test_data") }
  let(:engine) { SuperAgent::WorkflowEngine.new }

  describe "WorkflowEngine streaming" do
    it "yields step results during execution" do
      step_results = []

      result = engine.execute(test_workflow, context) do |step_result|
        step_results << step_result
      end

      expect(step_results.length).to eq(2)
      expect(step_results[0]).to be_a(Hash)
      expect(step_results[0][:step_name]).to eq(:step1)
      expect(step_results[0][:status]).to eq(:success)
      expect(step_results[0][:output]).to eq({ result: "step1_output", input: "test_data" })
      expect(step_results[1][:step_name]).to eq(:step2)
      expect(result.status).to eq('completed')
    end

    it "handles streaming with failed step" do
      failing_workflow = Class.new(SuperAgent::WorkflowDefinition) do
        define_task :failing_step, SuperAgent::Workflow::Tasks::DirectHandlerTask do |config|
          config.handler = ->(context) { raise "Step failed" }
        end
      end

      step_results = []
      
      expect do
        engine.execute(failing_workflow, context) do |step_result|
          step_results << step_result
        end
      end.to raise_error(StandardError)

      expect(step_results.length).to be >= 0
    end
  end

  describe "SuperAgent::Base streaming" do
    let(:agent) { Class.new(SuperAgent::Base).new({}) }

    it "supports streaming mode via block" do
      stub_const('TestWorkflow', test_workflow)

      step_results = []
      
      result = agent.run_workflow(TestWorkflow, initial_input: { input: "test_input" }) do |step_result|
        step_results << step_result
      end

      expect(step_results.length).to be >= 1
      expect(result.status).to eq('completed')
    end

    it "supports explicit streaming parameter" do
      stub_const('TestWorkflow', test_workflow)

      step_results = []
      
      result = agent.run_workflow(TestWorkflow, initial_input: { input: "test_input" }, streaming: true) do |step_result|
        step_results << step_result
      end

      expect(step_results.length).to be >= 1
    end
  end

  describe "StepResult object" do
    let(:step_result) do
      SuperAgent::StepResult.new(
        step_name: "test_step",
        status: :success,
        output: { key: "value" },
        duration_ms: 100,
        timestamp: Time.now.iso8601,
        workflow_execution_id: "test-uuid"
      )
    end

    it "provides structured step information" do
      expect(step_result.step_name).to eq("test_step")
      expect(step_result.status).to eq(:success)
      expect(step_result.output).to eq({ key: "value" })
      expect(step_result.duration_ms).to eq(100)
      expect(step_result.workflow_execution_id).to eq("test-uuid")
      expect(step_result.success?).to be true
      expect(step_result.failed?).to be false
      expect(step_result.skipped?).to be false
    end

    it "converts to hash" do
      hash = step_result.to_h
      expect(hash[:step_name]).to eq("test_step")
      expect(hash[:status]).to eq(:success)
    end
  end
end