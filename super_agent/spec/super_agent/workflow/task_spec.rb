# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SuperAgent::Workflow::Task do
  let(:task_name) { :test_task }
  let(:task_config) { { timeout: 30, retries: 2 } }
  let(:task) { described_class.new(task_name, task_config) }
  let(:context) { SuperAgent::Workflow::Context.new({ test: "data" }) }

  describe '#initialize' do
    it 'sets task name as symbol' do
      expect(task.name).to eq(:test_task)
    end

    it 'handles string names' do
      string_task = described_class.new("string_task")
      expect(string_task.name).to eq(:string_task)
    end

    it 'sets configuration' do
      expect(task.config).to eq(task_config)
    end

    it 'handles empty configuration' do
      empty_task = described_class.new(:empty)
      expect(empty_task.config).to eq({})
    end
  end

  describe '#execute' do
    it 'raises NotImplementedError' do
      expect { task.execute(context) }.to raise_error(NotImplementedError)
    end
  end

  describe '#validate!' do
    it 'returns true by default' do
      expect(task.validate!).to be true
    end
  end

  describe '#description' do
    it 'returns basic description' do
      expect(task.description).to include("SuperAgent::Workflow::Task task")
    end
  end

  describe '#timeout' do
    it 'returns configured timeout' do
      expect(task.timeout).to eq(30)
    end

    it 'returns default timeout when not configured' do
      default_task = described_class.new(:default)
      expect(default_task.timeout).to eq(SuperAgent.configuration.default_llm_timeout)
    end
  end

  describe '#retries' do
    it 'returns configured retries' do
      expect(task.retries).to eq(2)
    end

    it 'returns default retries when not configured' do
      default_task = described_class.new(:default)
      expect(default_task.retries).to eq(SuperAgent.configuration.default_llm_retries)
    end
  end

  describe '#should_execute?' do
    context 'without conditions' do
      it 'returns true' do
        expect(task.should_execute?(context)).to be true
      end
    end

    context 'with proc condition' do
      let(:true_proc) { proc { |ctx| ctx.get(:test) == "data" } }
      let(:false_proc) { proc { |ctx| ctx.get(:test) == "wrong" } }

      it 'returns true when condition is met' do
        task = described_class.new(:test, if: true_proc)
        expect(task.should_execute?(context)).to be true
      end

      it 'returns false when condition is not met' do
        task = described_class.new(:test, if: false_proc)
        expect(task.should_execute?(context)).to be false
      end
    end

    context 'with direct boolean condition' do
      it 'returns true for true value' do
        task = described_class.new(:test, if: true)
        expect(task.should_execute?(context)).to be true
      end

      it 'returns false for false value' do
        task = described_class.new(:test, if: false)
        expect(task.should_execute?(context)).to be false
      end
    end

    context 'with truthy/falsy values' do
      it 'returns true for truthy values' do
        task = described_class.new(:test, if: "truthy")
        expect(task.should_execute?(context)).to be true
      end

      it 'returns false for falsy values' do
        task = described_class.new(:test, if: false)
        expect(task.should_execute?(context)).to be false
      end
    end
  end

  describe 'private logging methods' do
    let(:logger) { double("logger") }

    before do
      allow(SuperAgent.configuration).to receive(:logger).and_return(logger)
    end

    describe '#log_start' do
      it 'logs start message' do
        expect(logger).to receive(:info).with("Starting task test_task", hash_including(:task, :context))
        task.send(:log_start, context)
      end
    end

    describe '#log_complete' do
      it 'logs complete message' do
        expect(logger).to receive(:info).with("Completed task test_task", hash_including(:task, :duration_ms, :result))
        task.send(:log_complete, context, "result", 100)
      end
    end

    describe '#log_error' do
      it 'logs error message' do
        error = StandardError.new("test error")
        expect(logger).to receive(:error).with("Failed task test_task", hash_including(:task, :error, :error_class))
        task.send(:log_error, context, error)
      end
    end
  end

  describe 'error handling' do
    it 'handles nil configuration gracefully' do
      nil_task = described_class.new(:nil_config, nil)
      expect(nil_task.config).to eq({})
      expect(nil_task.timeout).to eq(SuperAgent.configuration.default_llm_timeout)
    end

    it 'handles nil name gracefully' do
      nil_name_task = described_class.new(nil)
      expect(nil_name_task.name).to eq(nil)
    end
  end
end