module AnthropicTools
  # Class representing a tool result to send back to Claude
  #
  # The ToolResult class represents the result of a tool call that should be
  # sent back to Claude. It contains the tool use ID and the result content.
  #
  # @example Creating a tool result
  #   tool_result = AnthropicTools::ToolResult.new(
  #     tool_use_id: 'tool_use_123',
  #     content: 'The weather in San Francisco is 65°F and sunny.'
  #   )
  #   
  #   # Convert to a hash for API requests
  #   result_hash = tool_result.to_h
  #   
  #   # Send the result back to Claude
  #   client.chat(
  #     messages: [
  #       { role: 'user', content: 'What is the weather in San Francisco?' },
  #       { role: 'assistant', content: [{ type: 'tool_use', id: 'tool_use_123', name: 'get_weather', input: { location: 'San Francisco, CA' } }] },
  #       { role: 'user', content: [result_hash] }
  #     ]
  #   )
  class ToolResult
    # @return [String] The ID of the tool use request
    # @return [String, Hash] The result content
    # @return [Boolean] Whether the result is an error
    attr_reader :tool_use_id, :content, :is_error

    # Create a new tool result
    #
    # @param tool_use_id [String] The ID of the tool use request
    # @param content [String, Hash] The result content
    # @param is_error [Boolean] Whether the result is an error
    # @return [ToolResult] A new tool result instance
    def initialize(tool_use_id:, content:, is_error: false)
      @tool_use_id = tool_use_id
      @content = content
      @is_error = is_error
    end

    # Convert the tool result to a hash for API requests
    #
    # @return [Hash] A hash representation of the tool result
    def to_h
      result = {
        'type' => 'tool_result',
        'tool_use_id' => tool_use_id
      }
      
      # Handle different content formats
      if content.is_a?(Array) && content.all? { |c| c.is_a?(Hash) && (c.key?('type') || c.key?(:type)) }
        # Already in content block format - ensure string keys
        result['content'] = content.map do |block|
          block_with_string_keys = {}
          block.each do |k, v|
            block_with_string_keys[k.to_s] = v
          end
          block_with_string_keys
        end
      else
        # Convert to string content
        result['content'] = content.to_s
      end
      
      # Add error flag if present
      result['is_error'] = true if is_error
      
      result
    end
  end
end
