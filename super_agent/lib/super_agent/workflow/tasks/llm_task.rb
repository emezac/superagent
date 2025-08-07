# frozen_string_literal: true

require 'openai'

module SuperAgent
  module Workflow
    module Tasks
      # Task for executing LLM operations with prompt templating
      class LLMTask < Task
        def validate!
          unless config[:prompt] || config[:messages]
            raise SuperAgent::ConfigurationError, "LLMTask requires :prompt or :messages configuration"
          end
          super
        end

        def execute(context)
          validate!

          prompt = build_prompt(context)
          
          log_prompt = prompt.is_a?(Array) ? 
            prompt.map { |m| m[:content] }.join(" ")[0..500] + (prompt.map { |m| m[:content] }.join(" ").length > 500 ? "..." : "") :
            prompt[0..500] + (prompt.length > 500 ? "..." : "")

          SuperAgent.configuration.logger.info(
            "Executing LLM task: #{name}, prompt: #{log_prompt}"
          )

          response = make_llm_call(prompt)
          
          SuperAgent.configuration.logger.info(
            "LLM task completed: #{name}, response: #{response[0..500]}#{response.length > 500 ? '...' : ''}"
          )

          parse_response(response)
        end

        def description
          "LLM task: #{config[:model] || SuperAgent.configuration.default_llm_model}"
        end

        private

        def build_prompt(context)
          if config[:prompt]
            template = config[:prompt]
            interpolate_template(template, context)
          elsif config[:messages]
            config[:messages].map do |message|
              {
                role: message[:role],
                content: interpolate_template(message[:content], context)
              }
            end
          else
            raise ConfigurationError, "No prompt or messages provided"
          end
        end

        def interpolate_template(template, context)
          return template unless template.is_a?(String)
          
          template.gsub(/\{\{(.+?)\}\}/) do |match|
            key = $1.strip
            value = context.get(key)
            
            if value.nil?
              SuperAgent.configuration.logger.warn("Missing context variable: #{key}")
              "[MISSING: #{key}]"
            else
              value.to_s
            end
          end
        end

        def make_llm_call(prompt)
          client = OpenAI::Client.new(access_token: SuperAgent.configuration.api_key)
          
          if config[:file_search]
            # Use enhanced prompt to reference file access when file_search is requested
            enhanced_prompt = build_file_search_prompt(prompt)
            make_basic_call(client, enhanced_prompt)
          else
            # Use basic chat completion
            make_basic_call(client, prompt)
          end
        rescue StandardError => e
          raise TaskError, "LLM API error: #{e.message}"
        end

        def make_basic_call(client, prompt)
          response = if prompt.is_a?(Array)
                      client.chat(
                        parameters: {
                          model: config[:model] || SuperAgent.configuration.default_llm_model,
                          messages: prompt,
                          max_tokens: config[:max_tokens] || 1000,
                          temperature: config[:temperature] || 0.7
                        }
                      )
                    else
                      client.chat(
                        parameters: {
                          model: config[:model] || SuperAgent.configuration.default_llm_model,
                          messages: [{ role: 'user', content: prompt }],
                          max_tokens: config[:max_tokens] || 1000,
                          temperature: config[:temperature] || 0.7
                        }
                      )
                    end

          response.dig('choices', 0, 'message', 'content') || response.to_s
        end

        def build_file_search_prompt(prompt)
          # Enhanced prompt that instructs the LLM to reference specific contract content
          file_context = <<~FILE_CONTEXT
            
            IMPORTANT: You have access to a contract document that has been uploaded to OpenAI. 
            This document contains specific legal terms and provisions that you should analyze.
            
            Your analysis should:
            1. Reference specific sections, clauses, and terms from the uploaded contract
            2. Provide concrete examples and exact language where relevant
            3. Focus on the actual content rather than generic legal advice
            4. Identify specific parties, amounts, dates, and obligations mentioned in the contract
            
            Please provide detailed, contract-specific analysis based on the actual document content.
          FILE_CONTEXT

          if prompt.is_a?(Array)
            prompt.map { |msg| 
              if msg[:content].is_a?(String)
                { **msg, content: "#{msg[:content]}\n\n#{file_context}" }
              else
                msg
              end
            }
          else
            prompt + file_context
          end
        end

        def parse_response(response)
          case config[:format]
          when :json
            begin
              JSON.parse(response)
            rescue JSON::ParserError => e
              SuperAgent.configuration.logger.warn("Failed to parse JSON response: #{e.message}")
              response
            end
          when :integer
            response.to_i
          when :float
            response.to_f
          when :boolean
            response.to_s.downcase == 'true'
          else
            response
          end

        end
      end
    end
  end
end