require 'spec_helper'

RSpec.describe AnthropicTools::ToolResult do
  describe '#initialize' do
    it 'initializes with tool_use_id and content' do
      result = described_class.new(
        tool_use_id: 'call_12345',
        content: 'Result content'
      )
      
      expect(result.tool_use_id).to eq('call_12345')
      expect(result.content).to eq('Result content')
      expect(result.is_error).to be false
    end
    
    it 'initializes with error flag' do
      result = described_class.new(
        tool_use_id: 'call_12345',
        content: 'Error message',
        is_error: true
      )
      
      expect(result.tool_use_id).to eq('call_12345')
      expect(result.content).to eq('Error message')
      expect(result.is_error).to be true
    end
  end
  
  describe '#to_h' do
    it 'returns a hash representation with string content' do
      result = described_class.new(
        tool_use_id: 'call_12345',
        content: 'Result content'
      )
      
      expect(result.to_h).to eq({
        'type' => 'tool_result',
        'tool_use_id' => 'call_12345',
        'content' => 'Result content'
      })
    end
    
    it 'returns a hash representation with content blocks' do
      content_blocks = [
        { 'type' => 'text', 'text' => 'Result content' }
      ]
      
      result = described_class.new(
        tool_use_id: 'call_12345',
        content: content_blocks
      )
      
      expect(result.to_h).to eq({
        'type' => 'tool_result',
        'tool_use_id' => 'call_12345',
        'content' => content_blocks
      })
    end
    
    it 'includes is_error flag when true' do
      result = described_class.new(
        tool_use_id: 'call_12345',
        content: 'Error message',
        is_error: true
      )
      
      expect(result.to_h).to eq({
        'type' => 'tool_result',
        'tool_use_id' => 'call_12345',
        'content' => 'Error message',
        'is_error' => true
      })
    end
  end
end
