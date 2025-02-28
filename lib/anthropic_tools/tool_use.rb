module AnthropicTools
  class ToolUse
    attr_reader :id, :name, :input

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

    def to_h
      {
        id: id,
        name: name,
        input: input
      }
    end
  end
end
