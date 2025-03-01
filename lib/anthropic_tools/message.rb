module AnthropicTools
  # Class representing a message in a conversation with Claude
  #
  # The Message class represents a message in a conversation with Claude.
  # It can be a user message or an assistant message, and can contain
  # text content or tool results.
  #
  # @example Creating a simple text message
  #   message = AnthropicTools::Message.new(
  #     role: 'user',
  #     content: 'Hello, Claude!'
  #   )
  #
  # @example Creating a message with tool results
  #   tool_result = AnthropicTools::ToolResult.new(
  #     tool_use_id: 'tool_use_123',
  #     content: 'The weather in San Francisco is 65°F and sunny.'
  #   )
  #   
  #   message = AnthropicTools::Message.new(
  #     role: 'user',
  #     content: 'Here is the weather information you requested.',
  #     tool_results: [tool_result]
  #   )
  class Message
    # @return [String] The role of the message sender ('user' or 'assistant')
    # @return [String, Array<Hash>] The content of the message
    # @return [Array<ToolResult, Hash>, nil] The tool results to include with the message
    attr_reader :role, :content, :tool_results

    # Create a new message
    #
    # @param role [String] The role of the message sender ('user' or 'assistant')
    # @param content [String, Array<Hash>] The content of the message
    # @param tool_results [Array<ToolResult, Hash>, nil] The tool results to include with the message
    # @return [Message] A new message instance
    def initialize(role:, content:, tool_results: nil)
      @role = role
      @content = content
      @tool_results = tool_results
    end

    # Convert the message to a hash for API requests
    #
    # @return [Hash] A hash representation of the message
    def to_h
      message = { role: role }

      # Handle content based on its format
      if content.is_a?(Array) && content.all? { |c| c.is_a?(Hash) && c.key?('type') || c.key?(:type) }
        # Already in content block format - ensure keys are strings
        message[:content] = content.map do |block|
          block_with_string_keys = {}
          block.each do |k, v|
            block_with_string_keys[k.to_s] = v
          end
          block_with_string_keys
        end
      elsif content.is_a?(String)
        # Convert string to text content block
        message[:content] = [{ 'type' => 'text', 'text' => content }]
      else
        # Try to convert to string
        message[:content] = [{ 'type' => 'text', 'text' => content.to_s }]
      end

      # Add tool results if present
      if tool_results && !tool_results.empty?
        if role == 'user'
          # For user messages, tool results are part of the content array
          tool_results.each do |result|
            result_hash = result.is_a?(ToolResult) ? result.to_h : result
            # Convert symbol keys to strings
            string_key_hash = {}
            result_hash.each do |k, v|
              string_key_hash[k.to_s] = v
            end
            message[:content] << string_key_hash
          end
        end
      end

      message
    end
  end
end
