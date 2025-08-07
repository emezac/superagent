# frozen_string_literal: true

require 'spec_helper'
require 'active_job/test_helper'

RSpec.describe SuperAgent::WorkflowJob, type: :job do
  include ActiveJob::TestHelper

  let(:test_workflow) do
    Class.new(SuperAgent::WorkflowDefinition) do
      define_task :test_task, SuperAgent::Workflow::Tasks::DirectHandlerTask do |config|
        config.handler = ->(context) { { result: "success", input: context.input } }
      end
    end
  end

  let(:context_data) { { input: "test data" } }

  before do
    stub_const('TestWorkflow', test_workflow)
    allow(SuperAgent::ExecutionModel).to receive(:create_from_context).and_call_original
  end

  describe '#perform' do
    it 'executes the workflow successfully' do
      expect do
        described_class.perform_now('TestWorkflow', context_data)
      end.not_to raise_error
    end

    it 'creates an execution record' do
      described_class.perform_now('TestWorkflow', context_data)
      
      expect(SuperAgent::ExecutionModel).to have_received(:create_from_context)
        .with('TestWorkflow', context_data, hash_including(job_id: String))
    end

    it 'returns the workflow result' do
      result = described_class.perform_now('TestWorkflow', context_data)
      
      expect(result).to be_a(SuperAgent::WorkflowResult)
      expect(result.status).to eq('completed')
      expect(result.final_output).to eq({ result: "success", input: "test data" })
    end

    context 'when workflow raises an error' do
      let(:failing_workflow) do
        Class.new(SuperAgent::WorkflowDefinition) do
          define_task :failing_task, SuperAgent::Workflow::Tasks::DirectHandlerTask do |config|
            config.handler = ->(context) { raise "Workflow failed" }
          end
        end
      end

      before do
        stub_const('FailingWorkflow', failing_workflow)
      end

      it 'raises the error' do
        expect do
          described_class.perform_now('FailingWorkflow', context_data)
        end.to raise_error(RuntimeError, "Workflow failed")
      end

      it 'updates execution record with error' do
        allow(SuperAgent::ExecutionModel).to receive(:find_by).and_return(double('execution', update_from_result: true))
        
        expect do
          described_class.perform_now('FailingWorkflow', context_data)
        end.to raise_error(RuntimeError)
      end
    end

    context 'with GlobalID objects' do
      let(:user) { double('User', id: 1, to_global_id: double('GlobalID', to_s: 'gid://dummy/User/1')) }
      let(:context_with_global_id) { { user: user.to_global_id.to_s } }

      before do
        allow(GlobalID::Locator).to receive(:locate).with('gid://dummy/User/1').and_return(user)
      end

      it 'rehydrates GlobalID objects' do
        expect(GlobalID::Locator).to receive(:locate).with('gid://dummy/User/1')
        
        described_class.perform_now('TestWorkflow', context_with_global_id)
      end
    end

    context 'with nested GlobalID objects' do
      let(:users) { [double('User', to_global_id: double('GlobalID', to_s: 'gid://dummy/User/1'))] }
      let(:nested_context) { { users: users.map { |u| u.to_global_id.to_s } } }

      before do
        allow(GlobalID::Locator).to receive(:locate).and_return(double('User'))
      end

      it 'rehydrates nested GlobalID objects' do
        expect(GlobalID::Locator).to receive(:locate).exactly(users.length).times
        
        described_class.perform_now('TestWorkflow', nested_context)
      end
    end
  end

  describe 'integration with SuperAgent::Base' do
    let(:test_agent) do
      Class.new(SuperAgent::Base) do
        def test_action
          run_workflow_later(TestWorkflow, initial_input: params[:data])
          render json: { message: "Workflow queued" }
        end
      end
    end

    it 'enqueues the job when called from agent' do
      stub_const('TestAgent', test_agent)
      
      expect do
        TestAgent.new.test_action
      end.to have_enqueued_job(SuperAgent::WorkflowJob)
        .with('TestWorkflow', hash_including(:input))
    end
  end
end