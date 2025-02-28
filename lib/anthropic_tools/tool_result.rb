module AnthropicTools
  class ToolResult
    attr_reader :tool_use_id, :content

    def initialize(tool_use_id:, content:)
      @tool_use_id = tool_use_id
      @content = content
    end

    def to_h
      {
        tool_use_id: tool_use_id,
        content: content.to_s
      }
    end
  end
end
