require 'spec_helper'

RSpec.describe AnthropicTools::Message do
  describe '#initialize' do
    it 'initializes with role and content' do
      message = described_class.new(
        role: 'user',
        content: 'Hello'
      )
      
      expect(message.role).to eq('user')
      expect(message.content).to eq('Hello')
      expect(message.tool_results).to be_nil
    end
    
    it 'initializes with tool results' do
      tool_results = [
        AnthropicTools::ToolResult.new(
          tool_use_id: 'call_12345',
          content: 'Result content'
        )
      ]
      
      message = described_class.new(
        role: 'user',
        content: 'Hello',
        tool_results: tool_results
      )
      
      expect(message.role).to eq('user')
      expect(message.content).to eq('Hello')
      expect(message.tool_results).to eq(tool_results)
    end
  end
  
  describe '#to_h' do
    it 'converts string content to content block' do
      message = described_class.new(
        role: 'user',
        content: 'Hello'
      )
      
      expect(message.to_h).to eq({
        role: 'user',
        content: [{ 'type' => 'text', 'text' => 'Hello' }]
      })
    end
    
    it 'preserves content blocks if already in that format' do
      content_blocks = [
        { 'type' => 'text', 'text' => 'Hello' }
      ]
      
      message = described_class.new(
        role: 'user',
        content: content_blocks
      )
      
      expect(message.to_h).to eq({
        role: 'user',
        content: content_blocks
      })
    end
    
    it 'adds tool results to user message content' do
      tool_result = AnthropicTools::ToolResult.new(
        tool_use_id: 'call_12345',
        content: 'Result content'
      )
      
      message = described_class.new(
        role: 'user',
        content: [],
        tool_results: [tool_result]
      )
      
      expect(message.to_h).to eq({
        role: 'user',
        content: [
          {
            'type' => 'tool_result',
            'tool_use_id' => 'call_12345',
            'content' => 'Result content'
          }
        ]
      })
    end
    
    it 'does not add tool results to assistant messages' do
      tool_result = AnthropicTools::ToolResult.new(
        tool_use_id: 'call_12345',
        content: 'Result content'
      )
      
      message = described_class.new(
        role: 'assistant',
        content: 'Response',
        tool_results: [tool_result]
      )
      
      expect(message.to_h).to eq({
        role: 'assistant',
        content: [{ 'type' => 'text', 'text' => 'Response' }]
      })
    end
  end
end
