# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SuperAgent::Workflow::DirectHandlerTask do
  let(:task_name) { :direct_task }
  let(:context) { SuperAgent::Workflow::Context.new({ value: 42, name: "test" }) }

  describe '#validate!' do
    context 'with valid configuration' do
      it 'passes validation with :with proc' do
        task = described_class.new(task_name, with: proc { |ctx| ctx.get(:value) * 2 })
        expect { task.validate! }.not_to raise_error
      end

      it 'passes validation with :method symbol' do
        task = described_class.new(task_name, method: :value)
        expect { task.validate! }.not_to raise_error
      end
    end

    context 'with invalid configuration' do
      it 'raises ConfigurationError without :with or :method' do
        task = described_class.new(task_name, timeout: 30)
        expect { task.validate! }.to raise_error(SuperAgent::ConfigurationError, /requires :with.*or :method/)
      end
    end
  end

  describe '#execute' do
    context 'with proc handler' do
      it 'executes proc with context' do
        task = described_class.new(task_name, with: proc { |ctx| ctx.get(:value) * 2 })
        result = task.execute(context)
        expect(result).to eq(84)
      end

      it 'executes lambda with context' do
        task = described_class.new(task_name, with: ->(ctx) { ctx.get(:name).upcase })
        result = task.execute(context)
        expect(result).to eq("TEST")
      end

      it 'executes context instance_exec' do
        task = described_class.new(task_name, with: proc { get(:value) + 10 })
        result = task.execute(context)
        expect(result).to eq(52)
      end
    end

    context 'with method handler' do
      it 'gets value from context using symbol' do
        task = described_class.new(task_name, method: :value)
        result = task.execute(context)
        expect(result).to eq(42)
      end

      it 'gets value from context using string' do
        task = described_class.new(task_name, method: "name")
        result = task.execute(context)
        expect(result).to eq("test")
      end

      it 'returns nil for non-existent method' do
        task = described_class.new(task_name, method: :non_existent)
        result = task.execute(context)
        expect(result).to be_nil
      end
    end

    context 'with direct value' do
      it 'returns the value as-is' do
        task = described_class.new(task_name, with: "static_value")
        result = task.execute(context)
        expect(result).to eq("static_value")
      end

      it 'returns numeric value' do
        task = described_class.new(task_name, with: 123)
        result = task.execute(context)
        expect(result).to eq(123)
      end

      it 'returns hash value' do
        hash_value = { key: "value" }
        task = described_class.new(task_name, with: hash_value)
        result = task.execute(context)
        expect(result).to eq(hash_value)
      end
    end

    context 'edge cases' do
      it 'handles nil proc result' do
        task = described_class.new(task_name, with: proc { nil })
        result = task.execute(context)
        expect(result).to be_nil
      end

      it 'handles false proc result' do
        task = described_class.new(task_name, with: proc { false })
        result = task.execute(context)
        expect(result).to be false
      end

      it 'handles empty string result' do
        task = described_class.new(task_name, with: proc { "" })
        result = task.execute(context)
        expect(result).to eq("")
      end

      it 'handles zero result' do
        task = described_class.new(task_name, with: proc { 0 })
        result = task.execute(context)
        expect(result).to eq(0)
      end
    end

    context 'error handling' do
      it 'raises error for invalid proc' do
        task = described_class.new(task_name, with: proc { raise "test error" })
        expect { task.execute(context) }.to raise_error(RuntimeError, "test error")
      end

      it 'handles context with missing keys gracefully' do
        task = described_class.new(task_name, method: :missing_key)
        result = task.execute(context)
        expect(result).to be_nil
      end
    end
  end

  describe '#description' do
    it 'returns descriptive string' do
      task = described_class.new(:test_task, with: proc { "test" })
      expect(task.description).to eq("Direct handler execution for test_task")
    end
  end

  describe 'integration with context' do
    it 'can modify and return complex data structures' do
      complex_context = SuperAgent::Workflow::Context.new({
        items: [{ id: 1, name: "item1" }, { id: 2, name: "item2" }],
        multiplier: 3
      })

      task = described_class.new(task_name, with: proc {
        items = get(:items)
        multiplier = get(:multiplier)
        items.map { |item| item[:id] * multiplier }
      })

      result = task.execute(complex_context)
      expect(result).to eq([3, 6])
    end

    it 'can work with nested context data' do
      nested_context = SuperAgent::Workflow::Context.new({
        user: { profile: { settings: { theme: "dark" } } }
      })

      task = described_class.new(task_name, method: :user)
      result = task.execute(nested_context)
      expect(result).to eq({ profile: { settings: { theme: "dark" } } })
    end
  end
end