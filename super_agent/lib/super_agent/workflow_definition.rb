# frozen_string_literal: true

module SuperAgent
  # Base class for defining workflows
  class WorkflowDefinition
    class << self
      attr_reader :steps_definition

      def steps(&block)
        @steps_definition = []
        instance_eval(&block) if block_given?
      end

      def step(name, **config)
        @steps_definition << { name: name.to_sym, config: config }
      end

      def all_steps
        @steps_definition || []
      end
    end

    # Get all steps defined for this workflow
    def steps
      self.class.all_steps
    end

    # Get step by name
    def find_step(name)
      steps.find { |step| step[:name] == name.to_sym }
    end
  end
end