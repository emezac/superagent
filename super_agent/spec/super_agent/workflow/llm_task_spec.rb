# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SuperAgent::Workflow::LlmTask do
  let(:task_name) { :llm_task }
  let(:context) { SuperAgent::Workflow::Context.new({ user_name: "Alice", age: 30 }) }
  let(:mock_client) { instance_double(OpenAI::Client) }

  before do
    allow(OpenAI::Client).to receive(:new).and_return(mock_client)
    allow(SuperAgent.configuration).to receive(:api_key).and_return("test_api_key")
    allow(SuperAgent.configuration).to receive(:default_llm_model).and_return("gpt-3.5-turbo")
  end

  describe '#validate!' do
    context 'with valid configuration' do
      it 'passes validation with :prompt' do
        task = described_class.new(task_name, prompt: "Hello {{user_name}}")
        expect { task.validate! }.not_to raise_error
      end

      it 'passes validation with :messages' do
        messages = [{ role: "user", content: "Hello {{user_name}}" }]
        task = described_class.new(task_name, messages: messages)
        expect { task.validate! }.not_to raise_error
      end

      it 'passes validation with both prompt and messages' do
        task = described_class.new(task_name, prompt: "Hello", messages: [{ role: "user", content: "Hi" }])
        expect { task.validate! }.not_to raise_error
      end
    end

    context 'with invalid configuration' do
      it 'raises ConfigurationError without prompt or messages' do
        task = described_class.new(task_name, model: "gpt-4")
        expect { task.validate! }.to raise_error(SuperAgent::ConfigurationError, /requires :prompt or :messages/)
      end
    end
  end

  describe '#execute' do
    let(:response) do
      {
        "choices" => [
          {
            "message" => {
              "content" => "Hello Alice! You are 30 years old."
            }
          }
        ]
      }
    end

    before do
      allow(mock_client).to receive(:chat).and_return(response)
    end

    context 'with simple prompt' do
      let(:task) { described_class.new(task_name, prompt: "Hello {{user_name}}! You are {{age}} years old.") }

      it 'interpolates context variables' do
        result = task.execute(context)
        expect(mock_client).to have_received(:chat).with(
          parameters: hash_including(
            messages: [{ role: "user", content: "Hello Alice! You are 30 years old." }]
          )
        )
        expect(result).to eq("Hello Alice! You are 30 years old.")
      end

      it 'uses default model when not specified' do
        task.execute(context)
        expect(mock_client).to have_received(:chat).with(
          parameters: hash_including(model: "gpt-3.5-turbo")
        )
      end

      it 'uses custom model when specified' do
        custom_task = described_class.new(task_name, prompt: "Hello", model: "gpt-4")
        custom_task.execute(context)
        expect(mock_client).to have_received(:chat).with(
          parameters: hash_including(model: "gpt-4")
        )
      end

      it 'uses custom parameters' do
        custom_task = described_class.new(task_name, prompt: "Hello", max_tokens: 500, temperature: 0.5)
        custom_task.execute(context)
        expect(mock_client).to have_received(:chat).with(
          parameters: hash_including(max_tokens: 500, temperature: 0.5)
        )
      end
    end

    context 'with messages array' do
      let(:messages) do
        [
          { role: "system", content: "You are a helpful assistant" },
          { role: "user", content: "Hello {{user_name}}" }
        ]
      end
      let(:task) { described_class.new(task_name, messages: messages) }

      it 'interpolates context variables in messages' do
        task.execute(context)
        expect(mock_client).to have_received(:chat).with(
          parameters: hash_including(
            messages: [
              { role: "system", content: "You are a helpful assistant" },
              { role: "user", content: "Hello Alice" }
            ]
          )
        )
      end

      it 'handles messages without interpolation' do
        static_messages = [{ role: "user", content: "Hello world" }]
        static_task = described_class.new(task_name, messages: static_messages)
        static_task.execute(context)
        expect(mock_client).to have_received(:chat).with(
          parameters: hash_including(messages: static_messages)
        )
      end
    end

    context 'with prompt templating' do
      let(:task) { described_class.new(task_name, prompt: "{{greeting}} {{user_name}}!") }

      it 'interpolates single variable' do
        context_with_greeting = context.set(:greeting, "Hi")
        task.execute(context_with_greeting)
        expect(mock_client).to have_received(:chat).with(
          parameters: hash_including(
            messages: [{ role: "user", content: "Hi Alice!" }]
          )
        )
      end

      it 'handles missing variables with warning' do
        logger = double("logger")
        allow(SuperAgent.configuration).to receive(:logger).and_return(logger)
        allow(logger).to receive(:info)
        allow(logger).to receive(:warn)

        task.execute(context)
        expect(logger).to have_received(:warn).with("Missing context variable: greeting")
        expect(mock_client).to have_received(:chat).with(
          parameters: hash_including(
            messages: [{ role: "user", content: "[MISSING: greeting] Alice!" }]
          )
        )
      end

      it 'handles multiple variables' do
        context_with_greeting = context.set(:greeting, "Hello").set(:suffix, "Welcome")
        multi_task = described_class.new(task_name, prompt: "{{greeting}} {{user_name}}! {{suffix}}")
        multi_task.execute(context_with_greeting)
        expect(mock_client).to have_received(:chat).with(
          parameters: hash_including(
            messages: [{ role: "user", content: "Hello Alice! Welcome" }]
          )
        )
      end

      it 'handles nested variables' do
        nested_context = context.set(:user, { name: "Bob" })
        nested_task = described_class.new(task_name, prompt: "Hello {{user_name}} and {{user.name}}")
        nested_task.execute(nested_context)
        expect(mock_client).to have_received(:chat).with(
          parameters: hash_including(
            messages: [{ role: "user", content: "Hello Alice and [MISSING: user.name]" }]
          )
        )
      end
    end

    context 'response parsing' do
      let(:task) { described_class.new(task_name, prompt: "test", format: format) }

      context 'with json format' do
        let(:format) { :json }
        let(:json_response) do
          {
            "choices" => [
              { "message" => { "content" => '{"name": "Alice", "age": 30}' } }
            ]
          }
        end

        it 'parses valid JSON' do
          allow(mock_client).to receive(:chat).and_return(json_response)
          result = task.execute(context)
          expect(result).to eq({ "name" => "Alice", "age" => 30 })
        end

        it 'handles invalid JSON gracefully' do
          logger = double("logger")
          allow(SuperAgent.configuration).to receive(:logger).and_return(logger)
          allow(logger).to receive(:info)
          allow(logger).to receive(:warn)

          invalid_response = {
            "choices" => [
              { "message" => { "content" => "invalid json" } }
            ]
          }
          allow(mock_client).to receive(:chat).and_return(invalid_response)

          result = task.execute(context)
          expect(logger).to have_received(:warn).with(/Failed to parse JSON/)
          expect(result).to eq("invalid json")
        end
      end

      context 'with integer format' do
        let(:format) { :integer }
        let(:int_response) do
          {
            "choices" => [
              { "message" => { "content" => "42" } }
            ]
          }
        end

        it 'converts response to integer' do
          allow(mock_client).to receive(:chat).and_return(int_response)
          result = task.execute(context)
          expect(result).to eq(42)
        end
      end

      context 'with float format' do
        let(:format) { :float }
        let(:float_response) do
          {
            "choices" => [
              { "message" => { "content" => "3.14" } }
            ]
          }
        end

        it 'converts response to float' do
          allow(mock_client).to receive(:chat).and_return(float_response)
          result = task.execute(context)
          expect(result).to eq(3.14)
        end
      end

      context 'with boolean format' do
        let(:format) { :boolean }
        let(:true_response) do
          {
            "choices" => [
              { "message" => { "content" => "true" } }
            ]
          }
        end
        let(:false_response) do
          {
            "choices" => [
              { "message" => { "content" => "false" } }
            ]
          }
        end

        it 'converts "true" to boolean true' do
          allow(mock_client).to receive(:chat).and_return(true_response)
          result = task.execute(context)
          expect(result).to be true
        end

        it 'converts "false" to boolean false' do
          allow(mock_client).to receive(:chat).and_return(false_response)
          result = task.execute(context)
          expect(result).to be false
        end

        it 'handles case insensitive boolean conversion' do
          mixed_response = {
            "choices" => [
              { "message" => { "content" => "TRUE" } }
            ]
          }
          allow(mock_client).to receive(:chat).and_return(mixed_response)
          result = task.execute(context)
          expect(result).to be true
        end
      end

      context 'with no format specified' do
        let(:task) { described_class.new(task_name, prompt: "test") }

        it 'returns response as string' do
          result = task.execute(context)
          expect(result).to eq("Hello Alice! You are 30 years old.")
        end
      end
    end

    context 'error handling' do
      it 'raises TaskError on API failure' do
        allow(mock_client).to receive(:chat).and_raise(StandardError.new("API Error"))
        task = described_class.new(task_name, prompt: "test")
        expect { task.execute(context) }.to raise_error(SuperAgent::TaskError, /LLM API error/)
      end

      it 'handles empty response' do
        empty_response = { "choices" => [] }
        allow(mock_client).to receive(:chat).and_return(empty_response)
        task = described_class.new(task_name, prompt: "test")
        result = task.execute(context)
        expect(result).to eq(empty_response.to_s)
      end

      it 'handles missing content in response' do
        missing_content_response = { "choices" => [{ "message" => {} }] }
        allow(mock_client).to receive(:chat).and_return(missing_content_response)
        task = described_class.new(task_name, prompt: "test")
        result = task.execute(context)
        expect(result).to eq(missing_content_response.to_s)
      end
    end

    describe '#description' do
      it 'returns description with default model' do
        task = described_class.new(task_name, prompt: "test")
        expect(task.description).to eq("LLM task: gpt-3.5-turbo")
      end

      it 'returns description with custom model' do
        task = described_class.new(task_name, prompt: "test", model: "gpt-4")
        expect(task.description).to eq("LLM task: gpt-4")
      end
    end

    context 'logging' do
      let(:logger) { double("logger") }
      let(:task) { described_class.new(task_name, prompt: "Hello {{user_name}}") }

      before do
        allow(SuperAgent.configuration).to receive(:logger).and_return(logger)
        allow(logger).to receive(:info)
        allow(mock_client).to receive(:chat).and_return(response)
      end

      it 'logs start of LLM execution' do
        task.execute(context)
        expect(logger).to have_received(:info).with("Executing LLM task", hash_including(:task, :prompt))
      end

      it 'logs completion of LLM execution' do
        task.execute(context)
        expect(logger).to have_received(:info).with("LLM task completed", hash_including(:task, :response))
      end

      it 'truncates long prompts in logs' do
        long_prompt = "a" * 600
        long_task = described_class.new(task_name, prompt: long_prompt)
        long_task.execute(context)
        expect(logger).to have_received(:info).with(
          "Executing LLM task",
          hash_including(prompt: /a{500}.../)
        )
      end

      it 'truncates long responses in logs' do
        long_response = {
          "choices" => [
            { "message" => { "content" => "a" * 600 } }
          ]
        }
        allow(mock_client).to receive(:chat).and_return(long_response)
        task.execute(context)
        expect(logger).to have_received(:info).with(
          "LLM task completed",
          hash_including(response: /a{500}.../)
        )
      end
    end
  end
end