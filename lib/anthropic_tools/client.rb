require 'faraday'
require 'faraday/retry'
require 'json'

module AnthropicTools
  class Client
    attr_reader :config

    def initialize(config)
      @config = config
      validate_configuration
    end

    # Send a message to Claude
    def chat(messages, tools: [], system: nil, max_tokens: nil, temperature: nil, stream: false, 
             tool_choice: nil, disable_parallel_tool_use: nil, &block)
      payload = build_payload(messages, tools, system, max_tokens, temperature, 
                             tool_choice, disable_parallel_tool_use)
      
      if stream && block_given?
        stream_response(payload, &block)
      else
        full_response(payload)
      end
    end

    # Create a conversation object for easier handling of multi-turn conversations
    def create_conversation(system: nil)
      Conversation.new(self, system: system)
    end

    private

    def validate_configuration
      raise ConfigurationError, "API key is required" unless config.api_key
    end

    def connection
      @connection ||= Faraday.new(config.api_url) do |conn|
        conn.options.timeout = config.timeout
        conn.request :retry, { max: 2, interval: 0.5, retry_statuses: [429, 500, 502, 503, 504] }
        conn.headers = headers
        conn.request :json
        conn.response :json
      end
    end

    def headers
      {
        'Content-Type' => 'application/json',
        'x-api-key' => config.api_key,
        'anthropic-version' => config.api_version
      }
    end

    def build_payload(messages, tools, system, max_tokens, temperature, tool_choice, disable_parallel_tool_use)
      payload = {
        model: config.model,
        max_tokens: max_tokens || config.max_tokens,
        temperature: temperature || config.temperature
      }

      # Format messages array
      payload[:messages] = messages.is_a?(Array) ?
        messages.map { |m| m.is_a?(Message) ? m.to_h : m } :
        [messages.is_a?(Message) ? messages.to_h : messages]

      # Add system prompt if provided
      payload[:system] = system if system

      # Add tools if provided
      if tools && !tools.empty?
        payload[:tools] = tools.map { |t| t.is_a?(Tool) ? t.to_h : t }

        # Add tool_choice if provided
        if tool_choice
          payload[:tool_choice] = tool_choice
        end

        # Add disable_parallel_tool_use if provided
        if !disable_parallel_tool_use.nil?
          if payload[:tool_choice].is_a?(Hash)
            payload[:tool_choice][:disable_parallel_tool_use] = disable_parallel_tool_use
          else
            payload[:tool_choice] = { type: 'auto', disable_parallel_tool_use: disable_parallel_tool_use }
          end
        end
      end

      payload
    end

    def full_response(payload)
      response = connection.post('/v1/messages', payload)
      handle_response(response)
    end

    def stream_response(payload, &block)
      payload[:stream] = true

      response = connection.post('/v1/messages') do |req|
        req.body = payload.to_json
        req.options.on_data = Proc.new do |chunk, size, env|
          process_stream_chunk(chunk, &block)
        end
      end

      response.status == 200
    end

    def process_stream_chunk(chunk, &block)
      if chunk.start_with?("data: ")
        data = chunk.sub(/^data: /, '').strip
        return if data == "[DONE]"

        begin
          parsed = JSON.parse(data)
          block.call(parsed)
        rescue JSON::ParserError => e
          # Skip invalid JSON
        end
      end
    end

    def handle_response(response)
      case response.status
      when 200
        parse_response(response.body)
      when 400
        raise BadRequestError, response.body['error']['message']
      when 401
        raise AuthenticationError, "Invalid API key"
      when 429
        raise RateLimitError, "Rate limit exceeded"
      when 500..599
        raise ServerError, "Anthropic server error"
      else
        raise ApiError, "Unexpected error: #{response.body}"
      end
    end

    def parse_response(body)
      response = {
        id: body['id'],
        model: body['model'],
        role: body['role'] || 'assistant',
        stop_reason: body['stop_reason'],
        usage: body['usage']
      }

      # Extract content from content blocks
      if body['content']
        response[:content_blocks] = body['content']
        response[:content] = extract_content(body['content'])

        # Extract tool calls if present
        tool_use_blocks = body['content'].select { |block| block['type'] == 'tool_use' }
        if !tool_use_blocks.empty?
          response[:tool_calls] = tool_use_blocks.map { |block| ToolUse.new(block) }
        end
      end

      response
    end

    def extract_content(content_blocks)
      return "" unless content_blocks

      content_blocks
        .select { |block| block['type'] == 'text' }
        .map { |block| block['text'] }
        .join("")
    end
  end
end
