module AnthropicTools
  class Message
    attr_reader :role, :content, :function_responses, :tool_results

    def initialize(role:, content:, function_responses: nil, tool_results: nil)
      @role = role
      @content = content
      @function_responses = function_responses
      @tool_results = tool_results || function_responses
    end

    def to_h
      message = {
        role: role,
        content: content
      }

      if tool_results && !tool_results.empty?
        message[:tool_results] = tool_results.map do |result|
          result.is_a?(ToolResult) ? result.to_h : result
        end
      elsif function_responses && !function_responses.empty?
        message[:tool_results] = function_responses.map do |result|
          result.is_a?(FunctionResponse) || result.is_a?(ToolResult) ? result.to_h : result
        end
      end

      message
    end
  end
end
