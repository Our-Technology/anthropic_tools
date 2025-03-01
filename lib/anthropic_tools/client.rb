require 'faraday'
require 'faraday/retry'
require 'json'
require_relative 'stream_helper'
require_relative 'stream_controller'
require_relative 'middleware'
require_relative 'instrumentation'

module AnthropicTools
  # Main client for interacting with the Anthropic API
  #
  # The Client class provides methods for sending messages to Claude models,
  # handling responses, and managing tools. It supports both synchronous and
  # streaming requests, and includes features like automatic retries, middleware
  # processing, and instrumentation.
  #
  # @example Basic usage
  #   client = AnthropicTools::Client.new(api_key: ENV['ANTHROPIC_API_KEY'])
  #   
  #   response = client.chat(
  #     messages: [
  #       { role: 'user', content: 'Hello, Claude!' }
  #     ]
  #   )
  #   
  #   puts response[:content][0][:text]
  #
  # @example Using tools
  #   client = AnthropicTools::Client.new(api_key: ENV['ANTHROPIC_API_KEY'])
  #   
  #   tools = [
  #     {
  #       name: 'get_weather',
  #       description: 'Get the current weather for a location',
  #       input_schema: {
  #         type: 'object',
  #         properties: {
  #           location: { type: 'string', description: 'City and state, e.g. San Francisco, CA' }
  #         },
  #         required: ['location']
  #       }
  #     }
  #   ]
  #   
  #   response = client.chat(
  #     messages: [
  #       { role: 'user', content: 'What is the weather in San Francisco?' }
  #     ],
  #     tools: tools,
  #     tool_choice: 'auto'
  #   )
  #   
  #   # Handle tool calls in the response
  #   if response[:content][0][:type] == 'tool_use'
  #     tool_call = response[:content][0]
  #     # Process tool call and send tool output back to Claude
  #   end
  class Client
    # Create a new AnthropicTools client
    #
    # @param config [Hash] The client configuration
    # @return [Client] A new client instance
    def initialize(config)
      @config = config
      validate_configuration
    end

    # Send a message to Claude
    #
    # @param messages [Array<Hash>] The conversation messages
    # @param tools [Array<Hash>] Tool definitions (optional)
    # @param system [String] System prompt (optional)
    # @param max_tokens [Integer] Maximum tokens to generate (optional)
    # @param temperature [Float] Temperature for generation (optional)
    # @param stream [Boolean] Whether to stream the response (optional)
    # @param tool_choice [String, Hash] Tool choice strategy (optional)
    # @param disable_parallel_tool_use [Boolean] Disable parallel tool use (optional)
    # @return [Hash] The response from Claude
    # @raise [Error] If the request fails
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
    #
    # @param messages [Array<Hash>] The conversation messages
    # @param tools [Array<Hash>] Tool definitions (optional)
    # @param system [String] System prompt (optional)
    # @return [Hash] The token count
    # @raise [Error] If the request fails
    def count_tokens(messages, tools: [], system: nil)
      payload = {
        model: @config.model,
        messages: messages,
        tools: tools.empty? ? nil : tools.map(&:to_h),
        system: system
      }.compact
      
      begin
        # Create request object for middleware
        request = {
          method: :post,
          url: '/v1/messages/count_tokens',
          body: payload.to_json,
          headers: headers
        }
        
        # Process request through middleware
        request = @config.middleware_stack.process_request(request)
        
        # Start timing
        start_time = Time.now
        
        # Send request
        response = connection.post(request[:url], JSON.parse(request[:body]))
        
        # Create response object for middleware
        response_obj = {
          status: response.status,
          body: response.body,
          headers: response.headers,
          _request: request,
          _duration: Time.now - start_time
        }
        
        # Process response through middleware
        response_obj = @config.middleware_stack.process_response(response_obj)
        
        # Handle the response
        result = handle_response(response)
        
        # Extract the request ID from the response headers if available
        request_id = response.headers['x-request-id'] || response.headers['request-id']
        
        # Add the request ID to the result
        result[:_request_id] = request_id if request_id
        
        # Record metrics
        record_metrics(request, response_obj, result) if @config.metrics_collector
        
        return result
      rescue Faraday::ConnectionFailed => e
        raise APIConnectionError.new("Connection failed: #{e.message}")
      rescue Faraday::TimeoutError => e
        raise APIConnectionTimeoutError.new("Request timed out: #{e.message}")
      end
    end

    # Create a streaming response
    #
    # @param messages [Array<Hash>] The conversation messages
    # @param tools [Array<Hash>] Tool definitions (optional)
    # @param system [String] System prompt (optional)
    # @param max_tokens [Integer] Maximum tokens to generate (optional)
    # @param temperature [Float] Temperature for generation (optional)
    # @param tool_choice [String, Hash] Tool choice strategy (optional)
    # @param disable_parallel_tool_use [Boolean] Disable parallel tool use (optional)
    # @return [StreamHelper] A stream helper instance
    def stream(messages, tools: [], system: nil, max_tokens: nil, temperature: nil, 
               tool_choice: nil, disable_parallel_tool_use: nil)
      helper = StreamHelper.new(
        self, messages, tools, system, max_tokens, temperature, 
        tool_choice, disable_parallel_tool_use
      )
      helper
    end

    private

    # Validate the client configuration
    #
    # @raise [ConfigurationError] If the configuration is invalid
    def validate_configuration
      raise ConfigurationError.new("API key is required") unless @config.api_key
    end

    # Send a request and get a full response
    #
    # @param payload [Hash] The request payload
    # @return [Hash] The response from Claude
    # @raise [Error] If the request fails
    def full_response(payload)
      begin
        # Create request object for middleware
        request = {
          method: :post,
          url: '/v1/messages',
          body: payload.to_json,
          headers: headers
        }
        
        # Process request through middleware
        request = @config.middleware_stack.process_request(request)
        
        # Start timing
        start_time = Time.now
        
        # Send request
        response = connection.post(request[:url], JSON.parse(request[:body]))
        
        # Create response object for middleware
        response_obj = {
          status: response.status,
          body: response.body,
          headers: response.headers,
          _request: request,
          _duration: Time.now - start_time
        }
        
        # Process response through middleware
        response_obj = @config.middleware_stack.process_response(response_obj)
        
        # Handle the response
        result = handle_response(response)
        
        # Record metrics
        record_metrics(request, response_obj, result) if @config.metrics_collector
        
        return result
      rescue Faraday::ConnectionFailed => e
        raise APIConnectionError.new("Connection failed: #{e.message}")
      rescue Faraday::TimeoutError => e
        raise APIConnectionTimeoutError.new("Request timed out: #{e.message}")
      end
    end

    # Send a streaming request
    #
    # @param payload [Hash] The request payload
    # @yield [Hash] Yields each chunk of the response
    # @raise [Error] If the request fails
    def stream_response(payload, &block)
      # Add stream parameter to the request
      request = {
        method: :post,
        url: '/v1/messages',
        body: payload.to_json,
        headers: headers
      }
      request[:body] = JSON.parse(request[:body])
      request[:body][:stream] = true
      request[:body] = request[:body].to_json

      # Process request through middleware
      request = @config.middleware_stack.process_request(request)

      # Record request metrics
      if @config.metrics_collector
        @config.metrics_collector.record_request_start(
          method: request[:method],
          path: request[:url]
        )
      end

      # Start timing the request
      start_time = Time.now

      # Make the streaming request
      response = connection.post(request[:url]) do |req|
        req.headers = headers
        req.body = request[:body]
        req.options.on_data = StreamHelper.create_on_data_handler(&block)
      end

      # Create a response hash
      response_obj = {
        status: response.status,
        headers: response.headers,
        body: response.body,
        _request: request,
        _duration: Time.now - start_time
      }

      # Process response through middleware
      response_obj = @config.middleware_stack.process_response(response_obj)

      # Record response metrics
      if @config.metrics_collector
        @config.metrics_collector.record_request(
          method: request[:method],
          path: request[:url],
          status: response.status,
          duration: response_obj[:_duration]
        )
      end

      response
    end

    # Build the request payload
    #
    # @param messages [Array<Hash>] The conversation messages
    # @param tools [Array<Hash>] Tool definitions (optional)
    # @param system [String] System prompt (optional)
    # @param max_tokens [Integer] Maximum tokens to generate (optional)
    # @param temperature [Float] Temperature for generation (optional)
    # @param tool_choice [String, Hash] Tool choice strategy (optional)
    # @param disable_parallel_tool_use [Boolean] Disable parallel tool use (optional)
    # @return [Hash] The request payload
    def build_payload(messages, tools, system, max_tokens, temperature, tool_choice, disable_parallel_tool_use)
      payload = {
        model: @config.model,
        max_tokens: max_tokens || @config.max_tokens,
        temperature: temperature || @config.temperature
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

    # Get the Faraday connection
    #
    # @return [Faraday::Connection] The Faraday connection
    def connection
      @connection ||= Faraday.new(@config.api_url) do |conn|
        conn.options.timeout = @config.timeout
        conn.request :retry, { 
          max: @config.max_retries,
          interval: @config.retry_initial_delay,
          max_interval: @config.retry_max_delay,
          interval_randomness: @config.retry_jitter,
          retry_statuses: @config.retry_statuses,
          methods: [:post, :get]
        }
        conn.headers = headers
        conn.request :json
        conn.response :json
      end
    end

    # Get the request headers
    #
    # @return [Hash] The request headers
    def headers
      {
        'Content-Type' => 'application/json',
        'x-api-key' => @config.api_key,
        'anthropic-version' => @config.api_version
      }
    end

    # Handle a response from Claude
    #
    # @param response [Faraday::Response] The response from Claude
    # @return [Hash] The parsed response
    # @raise [Error] If the response is an error
    def handle_response(response)
      # Extract the request ID from the response headers if available
      request_id = response.headers['x-request-id'] || response.headers['request-id']
      
      case response.status
      when 200
        parse_response(response.body, request_id)
      when 400
        error_message = "Bad request: #{response.body}"
        raise BadRequestError.new(error_message, status_code: response.status, response: response.body, request_id: request_id)
      when 401
        raise AuthenticationError.new("Invalid API key", status_code: response.status, response: response.body, request_id: request_id)
      when 403
        raise PermissionDeniedError.new("Permission denied", status_code: response.status, response: response.body, request_id: request_id)
      when 404
        raise NotFoundError.new("Resource not found", status_code: response.status, response: response.body, request_id: request_id)
      when 422
        raise UnprocessableEntityError.new("Unprocessable entity", status_code: response.status, response: response.body, request_id: request_id)
      when 429
        raise RateLimitError.new("Rate limit exceeded", status_code: response.status, response: response.body, request_id: request_id)
      when 500
        raise InternalServerError.new("Internal server error", status_code: response.status, response: response.body, request_id: request_id)
      when 503
        raise ServiceUnavailableError.new("Service unavailable", status_code: response.status, response: response.body, request_id: request_id)
      when 500..599
        raise ServerError.new("Server error", status_code: response.status, response: response.body, request_id: request_id)
      else
        raise ApiError.new("Unexpected error: #{response.body}", status_code: response.status, response: response.body, request_id: request_id)
      end
    end

    # Parse a response from Claude
    #
    # @param body [String] The response body
    # @param request_id [String] The request ID
    # @return [Hash] The parsed response
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

    # Extract content from a message
    #
    # @param content_blocks [Array<Hash>] The content blocks
    # @return [String] The extracted content
    def extract_content(content_blocks)
      return "" unless content_blocks

      content_blocks
        .select { |block| block['type'] == 'text' }
        .map { |block| block['text'] }
        .join("")
    end
    
    # Record metrics for the request/response
    #
    # @param request [Hash] The request
    # @param response [Hash] The response
    # @param result [Hash] The result
    # @param streaming [Boolean] Whether the request was streaming
    def record_metrics(request, response, result, streaming: false)
      return unless @config.respond_to?(:metrics_collector) && @config.metrics_collector
      
      # Record request metrics
      @config.metrics_collector.record_request(
        method: request[:method],
        path: request[:url],
        status: response[:status],
        duration: response[:_duration]
      )
      
      # Record token usage if available
      if result && result[:usage]
        @config.metrics_collector.record_token_usage(
          input_tokens: result[:usage]['input_tokens'],
          output_tokens: result[:usage]['output_tokens']
        )
      end
    end
  end
end
