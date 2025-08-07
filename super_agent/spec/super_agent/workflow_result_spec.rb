# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SuperAgent::WorkflowResult do
  let(:sample_trace) do
    [
      {
        step_name: :step1,
        status: :success,
        output: "result1",
        duration_ms: 100,
        timestamp: "2024-01-01T12:00:00Z"
      },
      {
        step_name: :step2,
        status: :success,
        output: "result2",
        duration_ms: 200,
        timestamp: "2024-01-01T12:00:01Z"
      }
    ]
  end

  describe '#initialize' do
    it 'creates successful result' do
      result = described_class.new(
        status: :completed,
        final_output: "final result",
        full_trace: sample_trace,
        workflow_execution_id: "test-123",
        duration_ms: 300
      )

      expect(result.status).to eq(:completed)
      expect(result.completed?).to be true
      expect(result.failed?).to be false
      expect(result.final_output).to eq("final result")
      expect(result.error).to be_nil
    end

    it 'creates failed result' do
      result = described_class.new(
        status: :failed,
        error: "Something went wrong",
        failed_task_name: :step2,
        failed_task_error: "Step failed",
        full_trace: sample_trace,
        workflow_execution_id: "test-456",
        duration_ms: 150
      )

      expect(result.status).to eq(:failed)
      expect(result.completed?).to be false
      expect(result.failed?).to be true
      expect(result.error).to eq("Something went wrong")
      expect(result.failed_task_name).to eq(:step2)
      expect(result.failed_task_error).to eq("Step failed")
    end
  end

  describe '.success' do
    it 'creates success result with factory method' do
      result = described_class.success(
        final_output: "success output",
        full_trace: sample_trace,
        workflow_execution_id: "success-123",
        duration_ms: 250
      )

      expect(result.status).to eq(:completed)
      expect(result.final_output).to eq("success output")
      expect(result.completed?).to be true
      expect(result.error).to be_nil
    end
  end

  describe '.failure' do
    it 'creates failure result with factory method' do
      result = described_class.failure(
        error: "Workflow failed",
        failed_task_name: :problem_step,
        failed_task_error: "Task execution failed",
        full_trace: sample_trace,
        workflow_execution_id: "failure-456",
        duration_ms: 100
      )

      expect(result.status).to eq(:failed)
      expect(result.failed?).to be true
      expect(result.error).to eq("Workflow failed")
      expect(result.failed_task_name).to eq(:problem_step)
      expect(result.failed_task_error).to eq("Task execution failed")
    end
  end

  describe '#output_for' do
    let(:result) do
      described_class.success(
        final_output: "final",
        full_trace: sample_trace,
        workflow_execution_id: "test-789",
        duration_ms: 300
      )
    end

    it 'returns output for existing step' do
      expect(result.output_for(:step1)).to eq("result1")
      expect(result.output_for(:step2)).to eq("result2")
    end

    it 'returns output for string step name' do
      expect(result.output_for("step1")).to eq("result1")
    end

    it 'returns nil for non-existent step' do
      expect(result.output_for(:nonexistent)).to be_nil
    end

    it 'returns nil for nil step name' do
      expect(result.output_for(nil)).to be_nil
    end
  end

  describe '#outputs' do
    let(:result) do
      described_class.success(
        final_output: "final",
        full_trace: sample_trace,
        workflow_execution_id: "test-789",
        duration_ms: 300
      )
    end

    it 'returns hash of all step outputs' do
      outputs = result.outputs
      expect(outputs).to eq({
        step1: "result1",
        step2: "result2"
      })
    end

    it 'returns empty hash for empty trace' do
      empty_result = described_class.success(
        final_output: nil,
        full_trace: [],
        workflow_execution_id: "empty-test",
        duration_ms: 0
      )
      expect(empty_result.outputs).to eq({})
    end
  end

  describe '#error_message' do
    context 'with completed workflow' do
      let(:result) do
        described_class.success(
          final_output: "success",
          full_trace: [],
          workflow_execution_id: "complete-123",
          duration_ms: 100
        )
      end

      it 'returns nil' do
        expect(result.error_message).to be_nil
      end
    end

    context 'with failed workflow' do
      let(:result) do
        described_class.failure(
          error: "Workflow execution failed",
          failed_task_name: :failed_step,
          failed_task_error: "Task raised exception",
          full_trace: [],
          workflow_execution_id: "failed-456",
          duration_ms: 50
        )
      end

      it 'returns formatted error with task name' do
        expect(result.error_message).to eq("Failed at task 'failed_step': Task raised exception")
      end

      context 'without failed_task_error' do
        let(:result) do
          described_class.failure(
            error: "General workflow error",
            failed_task_name: nil,
            failed_task_error: nil,
            full_trace: [],
            workflow_execution_id: "general-error",
            duration_ms: 25
          )
        end

        it 'returns general error message' do
          expect(result.error_message).to eq("Workflow failed: General workflow error")
        end
      end
    end
  end

  describe '#summary' do
    context 'successful result' do
      let(:result) do
        described_class.success(
          final_output: "completed work",
          full_trace: [],
          workflow_execution_id: "summary-success",
          duration_ms: 1234
        )
      end

      it 'returns success summary with duration' do
        expect(result.summary).to eq("Workflow completed successfully in 1234ms")
      end
    end

    context 'failed result' do
      let(:result) do
        described_class.failure(
          error: "Processing failed",
          failed_task_name: :critical_step,
          failed_task_error: "Null pointer exception",
          full_trace: [],
          workflow_execution_id: "summary-failure",
          duration_ms: 567
        )
      end

      it 'returns error summary' do
        expect(result.summary).to eq("Failed at task 'critical_step': Null pointer exception")
      end
    end
  end

  describe '#to_h' do
    let(:result) do
      described_class.success(
        final_output: "test output",
        full_trace: sample_trace,
        workflow_execution_id: "hash-test-123",
        duration_ms: 999
      )
    end

    it 'returns complete hash representation' do
      hash = result.to_h
      expect(hash).to be_a(Hash)
      expect(hash[:status]).to eq(:completed)
      expect(hash[:final_output]).to eq("test output")
      expect(hash[:full_trace]).to eq(sample_trace)
      expect(hash[:workflow_execution_id]).to eq("hash-test-123")
      expect(hash[:duration_ms]).to eq(999)
      expect(hash[:error]).to be_nil
      expect(hash[:failed_task_name]).to be_nil
      expect(hash[:failed_task_error]).to be_nil
    end

    it 'includes all fields for failed result' do
      failed_result = described_class.failure(
        error: "Error occurred",
        failed_task_name: :error_step,
        failed_task_error: "Specific error",
        full_trace: sample_trace,
        workflow_execution_id: "hash-failed-456",
        duration_ms: 111
      )

      hash = failed_result.to_h
      expect(hash[:status]).to eq(:failed)
      expect(hash[:error]).to eq("Error occurred")
      expect(hash[:failed_task_name]).to eq(:error_step)
      expect(hash[:failed_task_error]).to eq("Specific error")
    end

    it 'is serializable to JSON' do
      expect { JSON.generate(result.to_h) }.not_to raise_error
    end
  end

  describe 'equality and comparison' do
    let(:result1) do
      described_class.success(
        final_output: "same",
        full_trace: sample_trace,
        workflow_execution_id: "test-1",
        duration_ms: 100
      )
    end

    let(:result2) do
      described_class.success(
        final_output: "same",
        full_trace: sample_trace,
        workflow_execution_id: "test-2",
        duration_ms: 100
      )
    end

    it 'treats different instances as different' do
      expect(result1).not_to eq(result2)
      expect(result1.object_id).not_to eq(result2.object_id)
    end

    it 'has different attributes' do
      expect(result1.workflow_execution_id).not_to eq(result2.workflow_execution_id)
    end
  end

  describe 'edge cases' do
    it 'handles nil final_output' do
      result = described_class.success(
        final_output: nil,
        full_trace: [],
        workflow_execution_id: "nil-test",
        duration_ms: 0
      )
      expect(result.final_output).to be_nil
      expect(result.completed?).to be true
    end

    it 'handles empty trace' do
      result = described_class.success(
        final_output: "empty trace",
        full_trace: [],
        workflow_execution_id: "empty-trace",
        duration_ms: 0
      )
      expect(result.full_trace).to eq([])
      expect(result.outputs).to eq({})
    end

    it 'handles zero duration' do
      result = described_class.success(
        final_output: "zero duration",
        full_trace: [],
        workflow_execution_id: "zero-test",
        duration_ms: 0
      )
      expect(result.duration_ms).to eq(0)
    end

    it 'handles complex final_output' do
      complex_output = {
        data: [1, 2, 3],
        metadata: { type: "array", count: 3 },
        status: "complete"
      }

      result = described_class.success(
        final_output: complex_output,
        full_trace: [],
        workflow_execution_id: "complex-test",
        duration_ms: 100
      )
      expect(result.final_output).to eq(complex_output)
    end
  end
end