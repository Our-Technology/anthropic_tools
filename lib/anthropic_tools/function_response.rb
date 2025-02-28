module AnthropicTools
  class FunctionResponse
    attr_reader :tool_call_id, :content

    def initialize(tool_call_id:, content:)
      @tool_call_id = tool_call_id
      @content = content
    end

    def to_h
      {
        tool_call_id: tool_call_id,
        content: content.to_s
      }
    end
  end
end
