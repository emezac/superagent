# frozen_string_literal: true

module SuperAgent
  module Workflow
    # Task for executing simple Ruby code blocks or method calls
    class DirectHandlerTask < Task
      def validate!
        unless config[:with] || config[:method]
          raise SuperAgent::ConfigurationError, "DirectHandlerTask requires :with (proc) or :method configuration"
        end
        super
      end

      def execute(context)
        validate!

        handler = config[:with] || config[:method]
        
        if config[:with] && handler.respond_to?(:call)
          # Execute proc/lambda with context
          context.instance_exec(context, &handler)
        elsif config[:method]
          # Call method on context data
          context.get(handler)
        else
          # Execute the handler as-is (for :with with direct values)
          handler
        end
      end

      def description
        "Direct handler execution for #{name}"
      end
    end
  end
end