# frozen_string_literal: true

module SuperAgent
  # Registry for managing available tasks/tools
  class ToolRegistry
    def initialize
      @tools = {}
      register_default_tools
    end

    # Register a new tool with the registry
    def register(name, tool_class)
      @tools[name.to_sym] = tool_class
    end

    # Get a tool by name
    def get(name)
      @tools[name.to_sym] or raise ArgumentError, "Tool not found: #{name}"
    end

    # List all registered tool names
    def tool_names
      @tools.keys
    end

    # Check if a tool is registered
    def registered?(name)
      @tools.key?(name.to_sym)
    end

    private

    def register_default_tools
      # Ensure all task classes are loaded
      begin
        require_relative 'workflow/tasks/llm_task' unless defined?(SuperAgent::Workflow::Tasks::LLMTask)
        require_relative 'workflow/tasks/web_search_task' unless defined?(SuperAgent::Workflow::Tasks::WebSearchTask)
        require_relative 'workflow/tasks/file_upload_task' unless defined?(SuperAgent::Workflow::Tasks::FileUploadTask)
        require_relative 'workflow/tasks/vector_store_management_task' unless defined?(SuperAgent::Workflow::Tasks::VectorStoreManagementTask)
        require_relative 'workflow/tasks/file_search_task' unless defined?(SuperAgent::Workflow::Tasks::FileSearchTask)
        require_relative 'workflow/tasks/cron_task' unless defined?(SuperAgent::Workflow::Tasks::CronTask)
        require_relative 'workflow/tasks/markdown_task' unless defined?(SuperAgent::Workflow::Tasks::MarkdownTask)
        require_relative 'workflow/tasks/image_generation_task' unless defined?(SuperAgent::Workflow::Tasks::ImageGenerationTask)
        require_relative 'workflow/direct_handler_task' unless defined?(SuperAgent::Workflow::Tasks::DirectHandlerTask)
        require_relative 'workflow/tasks/llm_completion_task' unless defined?(SuperAgent::Workflow::Tasks::LLMCompletionTask)
        require_relative 'workflow/tasks/pundit_policy_task' unless defined?(SuperAgent::Workflow::Tasks::PunditPolicyTask)
        require_relative 'workflow/tasks/active_record_find_task' unless defined?(SuperAgent::Workflow::Tasks::ActiveRecordFindTask)
        require_relative 'workflow/tasks/active_record_scope_task' unless defined?(SuperAgent::Workflow::Tasks::ActiveRecordScopeTask)
        require_relative 'workflow/tasks/action_mailer_task' unless defined?(SuperAgent::Workflow::Tasks::ActionMailerTask)
        require_relative 'workflow/tasks/turbo_stream_task' unless defined?(SuperAgent::Workflow::Tasks::TurboStreamTask)
      rescue LoadError => e
        # Files may not exist in all environments
      end

      # Register available tools
      register(:direct_handler, SuperAgent::Workflow::Tasks::DirectHandlerTask) if defined?(SuperAgent::Workflow::Tasks::DirectHandlerTask)
      register(:llm, SuperAgent::Workflow::Tasks::LLMTask) if defined?(SuperAgent::Workflow::Tasks::LLMTask)
      register(:llm_task, SuperAgent::Workflow::Tasks::LLMTask) if defined?(SuperAgent::Workflow::Tasks::LLMTask)
      register(:llm_completion, SuperAgent::Workflow::Tasks::LLMCompletionTask) if defined?(SuperAgent::Workflow::Tasks::LLMCompletionTask)
      register(:pundit_policy, SuperAgent::Workflow::Tasks::PunditPolicyTask) if defined?(SuperAgent::Workflow::Tasks::PunditPolicyTask)
      register(:active_record_find, SuperAgent::Workflow::Tasks::ActiveRecordFindTask) if defined?(SuperAgent::Workflow::Tasks::ActiveRecordFindTask)
      register(:active_record_scope, SuperAgent::Workflow::Tasks::ActiveRecordScopeTask) if defined?(SuperAgent::Workflow::Tasks::ActiveRecordScopeTask)
      register(:action_mailer, SuperAgent::Workflow::Tasks::ActionMailerTask) if defined?(SuperAgent::Workflow::Tasks::ActionMailerTask)
      register(:turbo_stream, SuperAgent::Workflow::Tasks::TurboStreamTask) if defined?(SuperAgent::Workflow::Tasks::TurboStreamTask)
      register(:web_search, SuperAgent::Workflow::Tasks::WebSearchTask) if defined?(SuperAgent::Workflow::Tasks::WebSearchTask)
      register(:file_upload, SuperAgent::Workflow::Tasks::FileUploadTask) if defined?(SuperAgent::Workflow::Tasks::FileUploadTask)
      register(:vector_store_management, SuperAgent::Workflow::Tasks::VectorStoreManagementTask) if defined?(SuperAgent::Workflow::Tasks::VectorStoreManagementTask)
      register(:file_search, SuperAgent::Workflow::Tasks::FileSearchTask) if defined?(SuperAgent::Workflow::Tasks::FileSearchTask)
      register(:cron, SuperAgent::Workflow::Tasks::CronTask) if defined?(SuperAgent::Workflow::Tasks::CronTask)
      register(:markdown, SuperAgent::Workflow::Tasks::MarkdownTask) if defined?(SuperAgent::Workflow::Tasks::MarkdownTask)
      register(:image_generation, SuperAgent::Workflow::Tasks::ImageGenerationTask) if defined?(SuperAgent::Workflow::Tasks::ImageGenerationTask)
      register(:assistant, SuperAgent::Workflow::Tasks::AssistantTask) if defined?(SuperAgent::Workflow::Tasks::AssistantTask)
      register(:file_content, SuperAgent::Workflow::Tasks::FileContentTask) if defined?(SuperAgent::Workflow::Tasks::FileContentTask)
    end
  end
end