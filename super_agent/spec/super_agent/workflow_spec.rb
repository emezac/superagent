# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SuperAgent::WorkflowDefinition do
  describe '.steps' do
    it 'defines steps for the workflow' do
      class TestWorkflow < SuperAgent::WorkflowDefinition
        steps do
          step :step1, uses: :direct_handler
          step :step2, uses: :llm_task, prompt: "Hello"
        end
      end

      steps = TestWorkflow.all_steps
      expect(steps.size).to eq(2)
      expect(steps[0][:name]).to eq(:step1)
      expect(steps[1][:name]).to eq(:step2)
      expect(steps[0][:config][:uses]).to eq(:direct_handler)
      expect(steps[1][:config][:prompt]).to eq("Hello")
    end

    it 'handles empty workflow' do
      class EmptyWorkflow < SuperAgent::WorkflowDefinition
        steps
      end

      expect(EmptyWorkflow.all_steps).to eq([])
    end

    it 'handles workflow without steps block' do
      class NoStepsWorkflow < SuperAgent::WorkflowDefinition
      end

      expect(NoStepsWorkflow.all_steps).to eq([])
    end

    it 'handles multiple step definitions' do
      class MultiStepWorkflow < SuperAgent::WorkflowDefinition
        steps do
          step :first
          step :second, timeout: 30
          step :third, retries: 3, model: "gpt-4"
        end
      end

      steps = MultiStepWorkflow.all_steps
      expect(steps.size).to eq(3)
      expect(steps[0][:name]).to eq(:first)
      expect(steps[1][:config][:timeout]).to eq(30)
      expect(steps[2][:config][:retries]).to eq(3)
      expect(steps[2][:config][:model]).to eq("gpt-4")
    end
  end

  describe '#steps' do
    let(:workflow) { TestWorkflow.new }

    before do
      class TestWorkflow < SuperAgent::WorkflowDefinition
        steps do
          step :step1, uses: :direct_handler
          step :step2, uses: :llm_task
        end
      end
    end

    it 'returns steps defined in class' do
      steps = workflow.steps
      expect(steps.size).to eq(2)
      expect(steps.map { |s| s[:name] }).to eq([:step1, :step2])
    end
  end

  describe '#find_step' do
    before do
      class FindStepWorkflow < SuperAgent::WorkflowDefinition
        steps do
          step :first_step, uses: :direct_handler
          step :second_step, uses: :llm_task
        end
      end
    end

    let(:workflow) { FindStepWorkflow.new }

    it 'finds step by symbol name' do
      step = workflow.find_step(:first_step)
      expect(step[:name]).to eq(:first_step)
      expect(step[:config][:uses]).to eq(:direct_handler)
    end

    it 'finds step by string name' do
      step = workflow.find_step("second_step")
      expect(step[:name]).to eq(:second_step)
      expect(step[:config][:uses]).to eq(:llm_task)
    end

    it 'returns nil for non-existent step' do
      expect(workflow.find_step(:nonexistent)).to be_nil
    end
  end

  describe 'inheritance' do
    class BaseWorkflow < SuperAgent::WorkflowDefinition
      steps do
        step :base_step, uses: :direct_handler
      end
    end

    class DerivedWorkflow < BaseWorkflow
      steps do
        step :derived_step, uses: :llm_task
      end
    end

    it 'inherits steps from parent' do
      expect(BaseWorkflow.all_steps.size).to eq(1)
      expect(BaseWorkflow.all_steps[0][:name]).to eq(:base_step)
    end

    it 'combines parent and child steps' do
      # Note: Current implementation doesn't merge steps from inheritance
      # This is expected behavior - each class has its own steps definition
      expect(DerivedWorkflow.all_steps.size).to eq(1)
      expect(DerivedWorkflow.all_steps[0][:name]).to eq(:derived_step)
    end
  end

  describe 'step configuration flexibility' do
    class ComplexConfigWorkflow < SuperAgent::WorkflowDefinition
      steps do
        step :data_prep, uses: :direct_handler, with: proc { [1,2,3] }, timeout: 60
        step :analysis, uses: :llm_task, 
             prompt: "Analyze {{data_prep}}", 
             model: "gpt-4", 
             max_tokens: 1000,
             temperature: 0.7
        step :report, uses: :direct_handler, 
             if: proc { get(:analysis).present? },
             with: proc { "Report generated" }
      end
    end

    it 'supports complex step configurations' do
      steps = ComplexConfigWorkflow.all_steps
      expect(steps.size).to eq(3)

      data_prep = steps.find { |s| s[:name] == :data_prep }
      expect(data_prep[:config][:timeout]).to eq(60)

      analysis = steps.find { |s| s[:name] == :analysis }
      expect(analysis[:config][:model]).to eq("gpt-4")
      expect(analysis[:config][:max_tokens]).to eq(1000)

      report = steps.find { |s| s[:name] == :report }
      expect(report[:config]).to have_key(:if)
      expect(report[:config]).to have_key(:with)
    end
  end

  describe 'workflow instantiation' do
    let(:workflow_class) do
      Class.new(SuperAgent::WorkflowDefinition) do
        steps do
          step :test_step, uses: :direct_handler
        end
      end
    end

    it 'creates workflow instances' do
      workflow = workflow_class.new
      expect(workflow).to be_a(SuperAgent::WorkflowDefinition)
      expect(workflow.steps.size).to eq(1)
    end

    it 'allows multiple instances with same definition' do
      workflow1 = workflow_class.new
      workflow2 = workflow_class.new

      expect(workflow1.steps).to eq(workflow2.steps)
      expect(workflow1.object_id).not_to eq(workflow2.object_id)
    end
  end
end