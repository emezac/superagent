# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SuperAgent::ExecutionModel, type: :model do
  let(:valid_attributes) do
    {
      workflow_class_name: 'TestWorkflow',
      initial_context: { input: 'test data' },
      status: 'pending',
      workflow_execution_id: SecureRandom.uuid
    }
  end

  describe 'validations' do
    it 'is valid with valid attributes' do
      execution = described_class.new(valid_attributes)
      expect(execution).to be_valid
    end

    it 'requires workflow_class_name' do
      execution = described_class.new(valid_attributes.merge(workflow_class_name: nil))
      expect(execution).not_to be_valid
      expect(execution.errors[:workflow_class_name]).to include("can't be blank")
    end

    it 'requires status to be valid' do
      execution = described_class.new(valid_attributes.merge(status: 'invalid'))
      expect(execution).not_to be_valid
      expect(execution.errors[:status]).to include('is not included in the list')
    end

    it 'requires unique workflow_execution_id' do
      described_class.create!(valid_attributes)
      duplicate = described_class.new(valid_attributes)
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:workflow_execution_id]).to include('has already been taken')
    end
  end

  describe 'scopes' do
    before do
      described_class.create!(valid_attributes.merge(status: 'pending'))
      described_class.create!(valid_attributes.merge(status: 'running'))
      described_class.create!(valid_attributes.merge(status: 'completed'))
      described_class.create!(valid_attributes.merge(status: 'failed'))
    end

    it 'filters by status' do
      expect(described_class.pending.count).to eq(1)
      expect(described_class.running.count).to eq(1)
      expect(described_class.completed.count).to eq(1)
      expect(described_class.failed.count).to eq(1)
    end
  end

  describe 'status methods' do
    let(:execution) { described_class.new(valid_attributes) }

    it 'returns correct status checks' do
      execution.status = 'pending'
      expect(execution.pending?).to be true
      expect(execution.running?).to be false
      expect(execution.completed?).to be false
      expect(execution.failed?).to be false

      execution.status = 'running'
      expect(execution.running?).to be true

      execution.status = 'completed'
      expect(execution.completed?).to be true

      execution.status = 'failed'
      expect(execution.failed?).to be true
    end
  end

  describe 'duration helpers' do
    let(:execution) { described_class.create!(valid_attributes) }

    it 'calculates duration_ms' do
      execution.started_at = 5.seconds.ago
      execution.completed_at = Time.current
      expect(execution.duration_ms).to be_within(100).of(5000)
    end

    it 'calculates running_duration_ms' do
      execution.started_at = 3.seconds.ago
      execution.status = 'running'
      expect(execution.running_duration_ms).to be_within(100).of(3000)
    end

    it 'returns nil for incomplete durations' do
      expect(execution.duration_ms).to be_nil
      expect(execution.running_duration_ms).to be_nil
    end
  end

  describe 'create_from_context' do
    it 'creates execution with UUID' do
      execution = described_class.create_from_context('TestWorkflow', { input: 'data' })
      expect(execution).to be_persisted
      expect(execution.workflow_execution_id).to match(/\A[0-9a-f-]+\z/i)
      expect(execution.status).to eq('pending')
    end
  end

  describe 'update_from_result' do
    let(:execution) { described_class.create!(valid_attributes) }
    let(:result) do
      SuperAgent::WorkflowResult.new(
        status: 'completed',
        final_output: { result: 'success' },
        error: nil,
        failed_task_name: nil,
        full_trace: [],
        duration_ms: 1000
      )
    end

    it 'updates from workflow result' do
      execution.update_from_result(result)
      execution.reload

      expect(execution.status).to eq('completed')
      expect(execution.final_output).to eq('result' => 'success')
      expect(execution.completed_at).to be_present
    end
  end

  describe 'JSON handling' do
    let(:execution) { described_class.create!(valid_attributes) }

    it 'handles string JSON' do
      execution.update!(initial_context: '{"key":"value"}')
      expect(execution.initial_context_hash).to eq('key' => 'value')
    end

    it 'handles hash JSON' do
      execution.update!(final_output: { key: 'value' })
      expect(execution.final_output_hash).to eq('key' => 'value')
    end
  end
end