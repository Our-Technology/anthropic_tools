module AnthropicTools
  class ToolResult
    attr_reader :tool_use_id, :content, :is_error

    def initialize(tool_use_id:, content:, is_error: false)
      @tool_use_id = tool_use_id
      @content = content
      @is_error = is_error
    end

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
