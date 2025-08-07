require 'net/http'
require 'json'
require 'uri'

module SuperAgent
  class LLMInterface
    def initialize
      @api_key = SuperAgent.configuration.api_key
      @base_url = 'https://api.openai.com/v1'
    end

    def complete(prompt:, model: nil, temperature: 0.7, max_tokens: nil)
      model ||= SuperAgent.configuration.default_llm_model
      
      uri = URI.parse("#{@base_url}/chat/completions")
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true

      request = Net::HTTP::Post.new(uri.request_uri)
      request['Content-Type'] = 'application/json'
      request['Authorization'] = "Bearer #{@api_key}"

      payload = {
        model: model,
        messages: messages_from_prompt(prompt),
        temperature: temperature
      }
      payload[:max_tokens] = max_tokens if max_tokens

      request.body = payload.to_json

      response = http.request(request)
      
      if response.code == '200'
        result = JSON.parse(response.body)
        result.dig('choices', 0, 'message', 'content')
      else
        raise "OpenAI API Error: #{response.code} - #{response.body}"
      end
    end

    private

    def messages_from_prompt(prompt)
      if prompt.is_a?(String)
        [{ role: 'user', content: prompt }]
      elsif prompt.is_a?(Array)
        prompt
      else
        [{ role: 'user', content: prompt.to_s }]
      end
    end
  end
end