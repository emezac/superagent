# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SuperAgent::WorkflowEngine do
  let(:engine) { described_class.new }
  let(:logger) { double("logger") }

  before do
    allow(SuperAgent.configuration).to receive(:logger).and_return(logger)
    allow(logger).to receive(:info)
    allow(logger).to receive(:error)
  end

  # Sample workflows for testing
  class TestWorkflow < SuperAgent::WorkflowDefinition
    steps do
      step :prepare_data, uses: :direct_handler, with: proc { |ctx| ctx.get(:input) * 2 }
      step :process_result, uses: :direct_handler, method: :prepare_data
      step :final_step, uses: :direct_handler, with: proc { |ctx| ctx.get(:process_result) + 10 }
    end
  end

  class ConditionalWorkflow < SuperAgent::WorkflowDefinition
    steps do
      step :always_run, uses: :direct_handler, with: proc { |ctx| "always" }
      step :conditional_step, uses: :direct_handler, if: proc { |ctx| ctx.get(:should_run) }, with: proc { "conditional" }
      step :final_step, uses: :direct_handler, with: proc { "final" }
    end
  end

  class FailingWorkflow < SuperAgent::WorkflowDefinition
    steps do
      step :success_step, uses: :direct_handler, with: proc { |ctx| "success" }
      step :failing_step, uses: :direct_handler, with: proc { |ctx| raise "Intentional error" }
      step :never_reached, uses: :direct_handler, with: proc { |ctx| "unreachable" }
    end
  end

  describe '#initialize' do
    it 'initializes with logger' do
      expect(engine.logger).to eq(SuperAgent.configuration.logger)
    end
  end

  describe '#execute' do
    context 'with successful workflow' do
      let(:initial_context) { SuperAgent::Workflow::Context.new(input: 5) }

      it 'executes all steps sequentially' do
        result = engine.execute(TestWorkflow, initial_context)

        expect(result.completed?).to be true
        expect(result.final_output).to eq(20) # (5 * 2) + 10
        expect(result.full_trace.size).to eq(3)

        # Check step outputs
        expect(result.output_for(:prepare_data)).to eq(10)
        expect(result.output_for(:process_result)).to eq(10)
        expect(result.output_for(:final_step)).to eq(20)
      end

      it 'generates unique workflow execution ID' do
        result1 = engine.execute(TestWorkflow, initial_context)
        result2 = engine.execute(TestWorkflow, initial_context)

        expect(result1.workflow_execution_id).not_to eq(result2.workflow_execution_id)
        expect(result1.workflow_execution_id).to match(/\A[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\z/i)
      end

      it 'includes duration in result' do
        result = engine.execute(TestWorkflow, initial_context)
        expect(result.duration_ms).to be_a(Integer)
        expect(result.duration_ms).to be >= 0
      end

      it 'logs workflow start and completion' do
        engine.execute(TestWorkflow, initial_context)

        expect(logger).to have_received(:info).with("Starting workflow execution", hash_including(
          workflow: "TestWorkflow",
          workflow_execution_id: instance_of(String),
          initial_context: hash_including(input: 5)
        ))

        expect(logger).to have_received(:info).with("Workflow execution completed", hash_including(
          workflow: "TestWorkflow",
          workflow_execution_id: instance_of(String),
          duration_ms: instance_of(Integer),
          status: :completed
        ))
      end

      it 'logs individual task execution' do
        engine.execute(TestWorkflow, initial_context)

        expect(logger).to have_received(:info).with("Executing task", hash_including(
          task: :prepare_data,
          workflow_execution_id: instance_of(String)
        )).at_least(:once)

        expect(logger).to have_received(:info).with("Task completed", hash_including(
          task: :prepare_data,
          workflow_execution_id: instance_of(String),
          duration_ms: instance_of(Integer)
        )).at_least(:once)
      end
    end

    context 'with conditional steps' do
      it 'skips conditional step when condition is false' do
        context = SuperAgent::Workflow::Context.new(should_run: false)
        result = engine.execute(ConditionalWorkflow, context)

        expect(result.completed?).to be true
        expect(result.full_trace.size).to eq(2) # always_run and final_step
        expect(result.output_for(:conditional_step)).to be_nil
        expect(result.output_for(:always_run)).to eq("always")
        expect(result.output_for(:final_step)).to eq("final")
      end

      it 'executes conditional step when condition is true' do
        context = SuperAgent::Workflow::Context.new(should_run: true)
        result = engine.execute(ConditionalWorkflow, context)

        expect(result.completed?).to be true
        expect(result.full_trace.size).to eq(3)
        expect(result.output_for(:conditional_step)).to eq("conditional")
      end
    end

    context 'with streaming' do
      it 'yields step results to block' do
        context = SuperAgent::Workflow::Context.new(input: 3)
        results = []

        engine.execute(TestWorkflow, context) do |step_result|
          results << step_result
        end

        expect(results.size).to eq(3)
        expect(results.map { |r| r[:step_name] }).to eq([:prepare_data, :process_result, :final_step])
        expect(results.all? { |r| r[:status] == :success }).to be true
      end
    end

    context 'with failing workflow' do
      let(:initial_context) { SuperAgent::Workflow::Context.new }

      it 'returns failure result' do
        result = engine.execute(FailingWorkflow, initial_context)

        expect(result.failed?).to be true
        expect(result.error).to include("Intentional error")
        expect(result.failed_task_name).to eq(:failing_step)
        expect(result.failed_task_error).to include("Intentional error")
      end

      it 'includes partial trace up to failure point' do
        result = engine.execute(FailingWorkflow, initial_context)

        expect(result.full_trace.size).to eq(2) # success_step and failing_step
        expect(result.output_for(:success_step)).to eq("success")
        expect(result.output_for(:failing_step)).to be_nil
      end

      it 'logs error details' do
        engine.execute(FailingWorkflow, initial_context)

        expect(logger).to have_received(:error).with("Task failed", hash_including(
          task: :failing_step,
          workflow_execution_id: instance_of(String),
          error: "Intentional error"
        ))

        expect(logger).to have_received(:error).with("Workflow execution failed", hash_including(
          workflow: "FailingWorkflow",
          workflow_execution_id: instance_of(String),
          error: "Intentional error",
          error_class: "RuntimeError"
        ))
      end

      it 'includes duration in failure result' do
        result = engine.execute(FailingWorkflow, initial_context)
        expect(result.duration_ms).to be_a(Integer)
        expect(result.duration_ms).to be >= 0
      end
    end

    context 'with empty context' do
      let(:empty_context) { SuperAgent::Workflow::Context.new }

      it 'handles empty context gracefully' do
        class EmptyContextWorkflow < SuperAgent::WorkflowDefinition
          steps do
            step :static_step, uses: :direct_handler, with: proc { "static result" }
          end
        end

        result = engine.execute(EmptyContextWorkflow, empty_context)
        expect(result.completed?).to be true
        expect(result.final_output).to eq("static result")
      end
    end

    context 'with complex data flow' do
      class DataFlowWorkflow < SuperAgent::WorkflowDefinition
        steps do
          step :generate_array, uses: :direct_handler, with: proc { [1, 2, 3] }
          step :transform_array, uses: :direct_handler, with: proc { |ctx| ctx.get(:generate_array).map { |x| x * 2 } }
          step :sum_array, uses: :direct_handler, with: proc { |ctx| ctx.get(:transform_array).sum }
          step :create_hash, uses: :direct_handler, with: proc { |ctx| { total: ctx.get(:sum_array), original: ctx.get(:generate_array) } }
        end
      end

      it 'passes complex data between steps' do
        context = SuperAgent::Workflow::Context.new
        result = engine.execute(DataFlowWorkflow, context)

        expect(result.completed?).to be true
        expect(result.final_output).to eq({ total: 12, original: [1, 2, 3] })
        expect(result.output_for(:generate_array)).to eq([1, 2, 3])
        expect(result.output_for(:transform_array)).to eq([2, 4, 6])
        expect(result.output_for(:sum_array)).to eq(12)
      end
    end

    context 'error handling' do
      it 'returns failure for unknown task type' do
        class UnknownTaskWorkflow < SuperAgent::WorkflowDefinition
          steps do
            step :unknown, uses: :nonexistent_task_type
          end
        end

        result = engine.execute(UnknownTaskWorkflow, SuperAgent::Workflow::Context.new)
        expect(result.failed?).to be true
        expect(result.error).to include("Tool not found")
      end

      it 'returns failure for missing task configuration' do
        class MissingConfigWorkflow < SuperAgent::WorkflowDefinition
          steps do
            step :missing_config
          end
        end

        result = engine.execute(MissingConfigWorkflow, SuperAgent::Workflow::Context.new)
        expect(result.failed?).to be true
        expect(result.error).to include("No task type specified")
      end
    end
  end

  describe 'integration with task types' do
    let(:mock_llm_client) { instance_double(OpenAI::Client) }

    before do
      allow(OpenAI::Client).to receive(:new).and_return(mock_llm_client)
      allow(SuperAgent.configuration).to receive(:api_key).and_return("test_key")
      allow(SuperAgent.configuration).to receive(:default_llm_model).and_return("gpt-3.5-turbo")
      allow(mock_llm_client).to receive(:chat).and_return(
        { "choices" => [{ "message" => { "content" => "LLM response" } }] }
      )
    end

    class MixedTaskWorkflow < SuperAgent::WorkflowDefinition
      steps do
        step :prepare, uses: :direct_handler, with: proc { "prepared data" }
        step :llm_process, uses: :llm_task, prompt: "Process {{prepare}}"
        step :finalize, uses: :direct_handler, with: proc { get(:llm_process).upcase }
      end
    end

    it 'integrates direct handler and LLM tasks' do
      context = SuperAgent::Workflow::Context.new
      result = engine.execute(MixedTaskWorkflow, context)

      expect(result.completed?).to be true
      expect(result.output_for(:prepare)).to eq("prepared data")
      expect(result.output_for(:llm_process)).to eq("LLM response")
      expect(result.output_for(:finalize)).to eq("LLM RESPONSE")
      expect(result.final_output).to eq("LLM RESPONSE")
    end
  end

  describe 'WorkflowResult methods' do
    let(:initial_context) { SuperAgent::Workflow::Context.new(input: 5) }
    let(:result) { engine.execute(TestWorkflow, initial_context) }

    describe '#output_for' do
      it 'returns output for specific step' do
        expect(result.output_for(:prepare_data)).to eq(10)
      end

      it 'returns nil for non-existent step' do
        expect(result.output_for(:nonexistent)).to be_nil
      end
    end

    describe '#outputs' do
      it 'returns hash of all step outputs' do
        outputs = result.outputs
        expect(outputs).to be_a(Hash)
        expect(outputs[:prepare_data]).to eq(10)
        expect(outputs[:process_result]).to eq(10)
        expect(outputs[:final_step]).to eq(20)
      end
    end

    describe '#error_message' do
      context 'with completed workflow' do
        it 'returns nil' do
          expect(result.error_message).to be_nil
        end
      end

      context 'with failed workflow' do
        let(:failed_result) { engine.execute(FailingWorkflow, SuperAgent::Workflow::Context.new) }

        it 'returns formatted error message' do
          expect(failed_result.error_message).to include("Failed at task 'failing_step'")
          expect(failed_result.error_message).to include("Intentional error")
        end
      end
    end

    describe '#summary' do
      context 'with completed workflow' do
        it 'returns success summary' do
          expect(result.summary).to include("completed successfully")
          expect(result.summary).to include("ms")
        end
      end

      context 'with failed workflow' do
        let(:failed_result) { engine.execute(FailingWorkflow, SuperAgent::Workflow::Context.new) }

        it 'returns error summary' do
          expect(failed_result.summary).to include("Failed at task")
          expect(failed_result.summary).to include("Intentional error")
        end
      end
    end

    describe '#to_h' do
      it 'returns hash representation' do
        hash = result.to_h
        expect(hash[:status]).to eq(:completed)
        expect(hash[:final_output]).to eq(20)
        expect(hash[:full_trace]).to be_a(Array)
        expect(hash[:workflow_execution_id]).to be_a(String)
        expect(hash[:duration_ms]).to be_a(Integer)
        expect(hash[:error]).to be_nil
      end
    end
  end
end