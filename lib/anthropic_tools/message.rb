module AnthropicTools
  class Message
    attr_reader :role, :content, :tool_results

    def initialize(role:, content:, tool_results: nil)
      @role = role
      @content = content
      @tool_results = tool_results
    end

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
