require 'spec_helper'

RSpec.describe AnthropicTools::ToolUse do
  describe '#initialize' do
    it 'initializes from the new API format' do
      data = {
        'type' => 'tool_use',
        'tool_use' => {
          'id' => 'call_12345',
          'name' => 'get_weather',
          'input' => { 'location' => 'New York' }
        }
      }
      
      tool_use = described_class.new(data)
      
      expect(tool_use.id).to eq('call_12345')
      expect(tool_use.name).to eq('get_weather')
      expect(tool_use.input).to eq({ 'location' => 'New York' })
    end
    
    it 'initializes from the direct format' do
      data = {
        'id' => 'call_12345',
        'name' => 'get_weather',
        'input' => { 'location' => 'New York' }
      }
      
      tool_use = described_class.new(data)
      
      expect(tool_use.id).to eq('call_12345')
      expect(tool_use.name).to eq('get_weather')
      expect(tool_use.input).to eq({ 'location' => 'New York' })
    end
  end
  
  describe '#to_h' do
    it 'returns a hash representation' do
      tool_use = described_class.new({
        'id' => 'call_12345',
        'name' => 'get_weather',
        'input' => { 'location' => 'New York' }
      })
      
      expect(tool_use.to_h).to eq({
        id: 'call_12345',
        name: 'get_weather',
        input: { 'location' => 'New York' }
      })
    end
  end
end
