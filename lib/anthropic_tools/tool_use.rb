module AnthropicTools
  # Class representing a tool use request from Claude
  #
  # The ToolUse class represents a request from Claude to use a tool.
  # It contains information about the tool to use, the input parameters,
  # and methods for handling the tool call.
  #
  # @example Handling a tool use request
  #   client = AnthropicTools::Client.new(api_key: ENV['ANTHROPIC_API_KEY'])
  #   
  #   response = client.chat(
  #     messages: [{ role: 'user', content: 'What is the weather in San Francisco?' }],
  #     tools: [weather_tool.to_h]
  #   )
  #   
  #   if response[:content][0][:type] == 'tool_use'
  #     tool_use = AnthropicTools::ToolUse.from_content(response[:content][0])
  #     
  #     # Handle the tool use request
  #     result = tool_use.call_tool(weather_tool)
  #     
  #     # Send the result back to Claude
  #     client.chat(
  #       messages: [
  #         { role: 'user', content: 'What is the weather in San Francisco?' },
  #         { role: 'assistant', content: [response[:content][0]] },
  #         { role: 'user', content: [{ type: 'tool_result', tool_use_id: tool_use.id, content: result }] }
  #       ]
  #     )
  #   end
  class ToolUse
    # @return [String] The ID of the tool use request
    # @return [String] The name of the tool to use
    # @return [Hash] The input parameters for the tool
    attr_reader :id, :name, :input

    # Create a new tool use request
    #
    # @param data [Hash] The data for the tool use request
    # @return [ToolUse] A new tool use request instance
    def initialize(data)
      if data.is_a?(Hash) && data.key?('tool_use')
        # New API format where tool_use is nested
        @id = data['tool_use']['id']
        @name = data['tool_use']['name']
        @input = data['tool_use']['input']
      else
        # Legacy or direct format
        @id = data['id']
        @name = data['name']
        @input = data['input']
      end
    end

    # Convert the tool use request to a hash
    #
    # @return [Hash] A hash representation of the tool use request
    def to_h
      {
        id: id,
        name: name,
        input: input
      }
    end
  end
end
