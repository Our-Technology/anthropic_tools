module AnthropicTools
  # Class for managing a conversation with Claude
  #
  # The Conversation class provides a convenient way to manage a conversation
  # with Claude, including tracking messages, handling tools, and processing
  # tool calls and results.
  #
  # @example Basic conversation
  #   client = AnthropicTools::Client.new(api_key: ENV['ANTHROPIC_API_KEY'])
  #   
  #   conversation = AnthropicTools::Conversation.new(client)
  #   conversation.add_user_message('Hello, Claude!')
  #   
  #   response = conversation.send
  #   puts response[:content][0][:text]
  #   
  #   # Continue the conversation
  #   response = conversation.send('Tell me more about yourself.')
  #   puts response[:content][0][:text]
  #
  # @example Using tools in a conversation
  #   client = AnthropicTools::Client.new(api_key: ENV['ANTHROPIC_API_KEY'])
  #   
  #   weather_tool = AnthropicTools::Tool.new(
  #     name: 'get_weather',
  #     description: 'Get the current weather for a location',
  #     input_schema: {
  #       type: 'object',
  #       properties: {
  #         location: { type: 'string', description: 'City and state, e.g. San Francisco, CA' }
  #       },
  #       required: ['location']
  #     }
  #   ) do |params|
  #     # Implement weather lookup logic here
  #     "It's 65°F and sunny in #{params['location']}"
  #   end
  #   
  #   conversation = AnthropicTools::Conversation.new(
  #     client,
  #     tools: [weather_tool]
  #   )
  #   
  #   response = conversation.send('What is the weather in San Francisco?')
  #   puts response[:content][0][:text]
  class Conversation
    # @return [Array<Message>] The messages in the conversation
    # @return [Hash, nil] The system message
    # @return [Array<Tool>] The tools available in the conversation
    attr_reader :messages, :system, :tools

    # Create a new conversation
    #
    # @param client [Client] The client to use for API requests
    # @param system [Hash, nil] The system message
    # @param tools [Array<Tool>] The tools available in the conversation
    # @return [Conversation] A new conversation instance
    def initialize(client, system: nil, tools: [])
      @client = client
      @system = system
      @tools = tools
      @messages = []
    end

    # Add a user message to the conversation
    #
    # @param content [String, Array<Hash>] The content of the message
    # @return [Conversation] The conversation instance for chaining
    def add_user_message(content)
      messages << Message.new(role: 'user', content: content)
      self
    end

    # Add an assistant message to the conversation
    #
    # @param content [String, Array<Hash>] The content of the message
    # @return [Conversation] The conversation instance for chaining
    def add_assistant_message(content)
      messages << Message.new(role: 'assistant', content: content)
      self
    end

    # Add tools to the conversation
    #
    # @param new_tools [Array<Tool>] The tools to add
    # @return [Conversation] The conversation instance for chaining
    def add_tools(*new_tools)
      @tools.concat(new_tools)
      self
    end

    # Send a message and get a response
    #
    # @param content [String, Array<Hash>, nil] The content of the message to send
    # @param max_tokens [Integer, nil] The maximum number of tokens to generate
    # @param temperature [Float, nil] The temperature for the model
    # @param tool_choice [String, nil] The tool choice
    # @param disable_parallel_tool_use [Boolean, nil] Whether to disable parallel tool use
    # @return [Hash] The response from Claude
    def send(content = nil, max_tokens: nil, temperature: nil, tool_choice: nil, disable_parallel_tool_use: nil)
      add_user_message(content) if content
      
      response = @client.chat(
        messages, 
        tools: tools, 
        system: system,
        max_tokens: max_tokens,
        temperature: temperature,
        tool_choice: tool_choice,
        disable_parallel_tool_use: disable_parallel_tool_use
      )
      
      if response[:tool_calls] && !response[:tool_calls].empty?
        # Process tool calls
        tool_results = process_tool_calls(response[:tool_calls])
        
        # Add assistant response with tool calls
        messages << Message.new(
          role: 'assistant',
          content: response[:content_blocks] || response[:content]
        )
        
        # Add user message with tool results
        messages << Message.new(
          role: 'user',
          content: [],
          tool_results: tool_results
        )
        
        # Send follow-up to get final response
        follow_up_response = @client.chat(
          messages, 
          tools: tools, 
          system: system,
          max_tokens: max_tokens,
          temperature: temperature
        )
        
        # Add the final assistant response
        messages << Message.new(
          role: 'assistant', 
          content: follow_up_response[:content_blocks] || follow_up_response[:content]
        )
        
        # Return the follow-up response
        follow_up_response
      else
        # Add normal assistant response
        messages << Message.new(
          role: 'assistant', 
          content: response[:content_blocks] || response[:content]
        )
        
        # Return the response
        response
      end
    end

    # Process tool calls and get results
    #
    # @param tool_calls [Array<ToolUse>] The tool calls to process
    # @return [Array<ToolResult>] The results of the tool calls
    def process_tool_calls(tool_calls)
      tool_calls.map do |tool_call|
        tool = tools.find { |t| t.name == tool_call.name }
        
        if tool&.implementation
          begin
            result = tool.call(tool_call.input)
            ToolResult.new(
              tool_use_id: tool_call.id,
              content: result
            )
          rescue => e
            ToolResult.new(
              tool_use_id: tool_call.id,
              content: e.message,
              is_error: true
            )
          end
        else
          ToolResult.new(
            tool_use_id: tool_call.id,
            content: "Tool not implemented",
            is_error: true
          )
        end
      end
    end

    # Clear all messages in the conversation
    #
    # @return [Conversation] The conversation instance for chaining
    def clear
      @messages = []
      self
    end

    # Convert the conversation to an array of message hashes
    #
    # @return [Array<Hash>] The messages as hashes
    def to_a
      messages.map(&:to_h)
    end
  end
end
