module SuperAgent
  module Workflows
    module SingleStep
      class LLMWorkflow < WorkflowDefinition
        task :llm_completion do
          uses :llm_completion
        end
      end
    end
  end
end