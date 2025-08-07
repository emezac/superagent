# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SuperAgent::Base do
  let(:user) { double('User', id: 1, class: double(name: 'User')) }
  let(:request) { double('Request', request_id: 'req123', remote_ip: '127.0.0.1', user_agent: 'test-agent', session: double(id: 'sess123')) }
  let(:params) { { name: 'Test', data: { key: 'value' } } }
  
  let(:agent) do
    described_class.new(
      current_user: user,
      request: request,
      params: params,
      context: { additional: 'context' }
    )
  end

  describe '#initialize' do
    it 'sets up agent context' do
      expect(agent.current_user).to eq(user)
      expect(agent.request).to eq(request)
      expect(agent.params).to eq(params)
      expect(agent.context).to eq({ additional: 'context' })
    end

    it 'works with minimal parameters' do
      minimal_agent = described_class.new
      expect(minimal_agent.current_user).to be_nil
      expect(minimal_agent.request).to be_nil
      expect(minimal_agent.params).to eq({})
      expect(minimal_agent.context).to eq({})
    end
  end

  describe '#agent_context' do
    it 'returns structured context data' do
      context = agent.agent_context
      
      expect(context).to include(
        current_user_id: 1,
        current_user_type: 'User',
        request_id: 'req123',
        remote_ip: '127.0.0.1',
        user_agent: 'test-agent',
        session_id: 'sess123'
      )
    end

    it 'handles nil values gracefully' do
      minimal_agent = described_class.new
      context = minimal_agent.agent_context
      
      expect(context).to eq({})
    end
  end

  describe '#run_workflow' do
    let(:workflow_class) { double('WorkflowClass') }
    let(:engine) { instance_double(SuperAgent::WorkflowEngine) }
    let(:context) { instance_double(SuperAgent::Workflow::Context) }
    let(:result) { instance_double(SuperAgent::WorkflowResult, completed?: true) }

    before do
      allow(SuperAgent::WorkflowEngine).to receive(:new).and_return(engine)
      allow(engine).to receive(:execute).and_return(result)
      allow(SuperAgent::Workflow::Context).to receive(:new).and_return(context)
    end

    it 'creates workflow context correctly' do
      expect(agent).to receive(:create_workflow_context).with({ test: 'input' }).and_return(context)
      agent.run_workflow(workflow_class, initial_input: { test: 'input' })
    end

    it 'executes workflow with engine' do
      expect(engine).to receive(:execute).with(workflow_class, context)
      agent.run_workflow(workflow_class)
    end

    it 'supports streaming mode' do
      block = proc { |step| puts "Step: #{step}" }
      expect(engine).to receive(:execute).with(workflow_class, context, &block)
      agent.run_workflow(workflow_class, streaming: true, &block)
    end

    it 'returns workflow result' do
      expect(agent.run_workflow(workflow_class)).to eq(result)
    end
  end

  describe '#run_workflow_later' do
    let(:workflow_class) { class_double('TestWorkflow') }
    let(:context) { instance_double(SuperAgent::Workflow::Context, to_h: { test: 'data' }) }

    before do
      allow(workflow_class).to receive(:name).and_return('TestWorkflow')
      allow(SuperAgent::Workflow::Context).to receive(:new).and_return(context)
    end

    it 'enqueues workflow job' do
      expect(SuperAgent::WorkflowJob).to receive(:perform_later)
        .with('TestWorkflow', { test: 'data' })
      agent.run_workflow_later(workflow_class)
    end

    it 'creates context with merged data' do
      expect(agent).to receive(:create_workflow_context).with({ test: 'input' }).and_return(context)
      agent.run_workflow_later(workflow_class, initial_input: { test: 'input' })
    end
  end

  describe '#create_workflow_context' do
    it 'merges contexts with correct precedence' do
      initial_input = { override: 'value', new_data: 'present' }
      context = agent.send(:create_workflow_context, initial_input)
      
      expect(context).to be_a(SuperAgent::Workflow::Context)
      expect(context.get(:current_user_id)).to eq(1)
      expect(context.get(:override)).to eq('value')
      expect(context.get(:new_data)).to eq('present')
      expect(context.get(:additional)).to eq('context')
    end

    it 'filters sensitive data' do
      allow(SuperAgent.configuration).to receive(:sensitive_log_filter).and_return(%w[password])
      
      agent_with_password = described_class.new(
        params: { password: 'secret123', name: 'test' },
        context: { password: 'secret456', name: 'test' }
      )
      
      context = agent_with_password.send(:create_workflow_context, {})
      
      expect(context.get(:password)).to eq('[FILTERED]')
    end

    it 'validates serializable data' do
      # Test the validation method directly with a custom class
      class NonSerializable
        def to_json(*args)
          raise JSON::GeneratorError, "Cannot serialize #{self.class}"
        end
      end
      expect {
        agent.send(:validate_serializable, { unserializable: NonSerializable.new })
      }.to raise_error(ArgumentError)
    end
  end

  describe '#filter_sensitive_data' do
    before do
      allow(SuperAgent.configuration).to receive(:sensitive_log_filter).and_return(%w[password token])
    end

    it 'filters exact matches' do
      data = { password: 'secret', name: 'test' }
      filtered = agent.send(:filter_sensitive_data, data)
      
      expect(filtered[:password]).to eq('[FILTERED]')
      expect(filtered[:name]).to eq('test')
    end

    it 'filters partial matches' do
      data = { api_password: 'secret', name: 'test' }
      filtered = agent.send(:filter_sensitive_data, data)
      
      expect(filtered[:api_password]).to eq('[FILTERED]')
    end

    it 'handles regexp filters' do
      allow(SuperAgent.configuration).to receive(:sensitive_log_filter).and_return([/secret/i])
      
      data = { secret_key: 'value', public_data: 'safe' }
      filtered = agent.send(:filter_sensitive_data, data)
      
      expect(filtered[:secret_key]).to eq('[FILTERED]')
      expect(filtered[:public_data]).to eq('safe')
    end

    it 'handles proc filters' do
      filter_proc = proc { |key, value| key.to_s.include?('secret') }
      allow(SuperAgent.configuration).to receive(:sensitive_log_filter).and_return([filter_proc])
      
      data = { secret_data: 'value', safe_data: 'safe' }
      filtered = agent.send(:filter_sensitive_data, data)
      
      expect(filtered[:secret_data]).to eq('[FILTERED]')
      expect(filtered[:safe_data]).to eq('safe')
    end
  end

  describe 'integration with workflow engine' do
    class TestIntegrationWorkflow < SuperAgent::WorkflowDefinition
      steps do
        step :test_step, uses: :direct_handler, with: proc { |ctx| ctx.get(:test_data) }
      end
    end

    it 'successfully executes a real workflow' do
      result = agent.run_workflow(TestIntegrationWorkflow, 
                                initial_input: { test_data: 'hello world' })
      
      expect(result).to be_a(SuperAgent::WorkflowResult)
      expect(result.completed?).to be true
      expect(result.final_output).to eq('hello world')
    end

    it 'handles workflow failures gracefully' do
      class FailingIntegrationWorkflow < SuperAgent::WorkflowDefinition
        steps do
          step :failing_step, uses: :direct_handler, with: proc { raise 'Test error' }
        end
      end

      result = agent.run_workflow(FailingIntegrationWorkflow)
      
      expect(result.failed?).to be true
      expect(result.error).to include('Test error')
    end
  end
end