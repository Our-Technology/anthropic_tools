module AnthropicTools
  class Conversation
    attr_reader :messages, :system, :tools

    def initialize(client, system: nil, tools: [])
      @client = client
      @system = system
      @tools = tools
      @messages = []
    end

    def add_user_message(content)
      messages << Message.new(role: 'user', content: content)
      self
    end

    def add_assistant_message(content)
      messages << Message.new(role: 'assistant', content: content)
      self
    end

    def add_tools(*new_tools)
      @tools.concat(new_tools)
      self
    end

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

    def clear
      @messages = []
      self
    end

    def to_a
      messages.map(&:to_h)
    end
  end
end
