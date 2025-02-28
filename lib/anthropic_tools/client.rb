require 'faraday'
require 'faraday/retry'
require 'json'
require_relative 'stream_helper'
require_relative 'stream_controller'

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

    # Count tokens for a message without sending it
    def count_tokens(messages, tools: [], system: nil)
      payload = {
        model: config.model,
        messages: messages,
        tools: tools.empty? ? nil : tools.map(&:to_h),
        system: system
      }.compact
      
      begin
        response = connection.post('/v1/messages/count_tokens', payload)
        result = handle_response(response)
        
        # Extract the request ID from the response headers if available
        request_id = response.headers['x-request-id'] || response.headers['request-id']
        
        # Add the request ID to the result
        result[:_request_id] = request_id if request_id
        
        return result
      rescue Faraday::ConnectionFailed => e
        raise APIConnectionError.new("Connection failed: #{e.message}")
      rescue Faraday::TimeoutError => e
        raise APIConnectionTimeoutError.new("Connection timed out: #{e.message}")
      rescue Faraday::Error => e
        raise APIConnectionError.new("Error connecting to API: #{e.message}")
      end
    end

    # Create a conversation object for easier handling of multi-turn conversations
    def create_conversation(system: nil)
      Conversation.new(self, system: system)
    end

    # Stream helper with improved interface
    def stream(messages, tools: [], system: nil, max_tokens: nil, temperature: nil,
               tool_choice: nil, disable_parallel_tool_use: nil)
      StreamHelper.new(self, messages, tools, system, max_tokens, temperature, 
                      tool_choice, disable_parallel_tool_use)
    end

    private

    def validate_configuration
      raise ConfigurationError, "API key is required" unless config.api_key
    end

    def connection
      @connection ||= Faraday.new(config.api_url) do |conn|
        conn.options.timeout = config.timeout
        conn.request :retry, { 
          max: config.max_retries,
          interval: config.retry_initial_delay,
          max_interval: config.retry_max_delay,
          interval_randomness: config.retry_jitter,
          retry_statuses: config.retry_statuses,
          methods: [:post, :get]
        }
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
      # Calculate dynamic timeout for large requests if not streaming
      if !payload[:stream] && payload[:max_tokens] && payload[:max_tokens] > 4096
        timeout = config.calculate_timeout(payload[:max_tokens])
      else
        timeout = config.timeout
      end

      begin
        response = connection.post('/v1/messages', payload) do |req|
          req.options.timeout = timeout if timeout != config.timeout
        end
        
        handle_response(response)
      rescue Faraday::ConnectionFailed => e
        raise APIConnectionError.new("Connection failed: #{e.message}")
      rescue Faraday::TimeoutError => e
        raise APIConnectionTimeoutError.new("Connection timed out: #{e.message}")
      rescue Faraday::Error => e
        raise APIConnectionError.new("Error connecting to API: #{e.message}")
      end
    end

    def stream_response(payload, &block)
      payload[:stream] = true

      response = connection.post('/v1/messages') do |req|
        req.body = payload.to_json
        req.options.on_data = Proc.new do |chunk, size, env|
          process_stream_chunk(chunk, &block)
        end
      end

      if response.status != 200
        handle_response(response)
      end
      
      true
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
      # Extract request ID if available
      request_id = response.headers['x-request-id'] || response.headers['request-id']
      
      case response.status
      when 200
        parse_response(response.body, request_id)
      when 400
        error_message = response.body['error']['message'] rescue "Bad request"
        raise BadRequestError.new(error_message, response.status, response.body, request_id)
      when 401
        raise AuthenticationError.new("Invalid API key", response.status, response.body, request_id)
      when 403
        raise PermissionDeniedError.new("Permission denied", response.status, response.body, request_id)
      when 404
        raise NotFoundError.new("Resource not found", response.status, response.body, request_id)
      when 422
        raise UnprocessableEntityError.new("Unprocessable entity", response.status, response.body, request_id)
      when 429
        raise RateLimitError.new("Rate limit exceeded", response.status, response.body, request_id)
      when 500
        raise InternalServerError.new("Internal server error", response.status, response.body, request_id)
      when 503
        raise ServiceUnavailableError.new("Service unavailable", response.status, response.body, request_id)
      when 500..599
        raise ServerError.new("Server error", response.status, response.body, request_id)
      else
        raise ApiError.new("Unexpected error: #{response.body}", response.status, response.body, request_id)
      end
    end

    def parse_response(body, request_id = nil)
      # Parse the JSON body if it's a string
      parsed_body = body.is_a?(String) ? JSON.parse(body) : body
      
      # For token counting requests
      if parsed_body.key?('input_tokens')
        return {
          input_tokens: parsed_body['input_tokens'],
          _request_id: request_id
        }
      end
      
      response = {
        id: parsed_body['id'],
        model: parsed_body['model'],
        role: parsed_body['role'] || 'assistant',
        stop_reason: parsed_body['stop_reason'],
        usage: parsed_body['usage'],
        _request_id: request_id
      }

      # Extract content from the message
      if parsed_body['content']
        response[:content_blocks] = parsed_body['content']
        response[:content] = extract_content(parsed_body['content'])
        
        # Extract tool calls if present
        tool_use_blocks = parsed_body['content'].select { |block| block['type'] == 'tool_use' }
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
