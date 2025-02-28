require 'spec_helper'

RSpec.describe AnthropicTools::Tool do
  describe '#initialize' do
    it 'creates a tool with input_schema' do
      tool = described_class.new(
        name: 'test_tool',
        description: 'This is a test tool that demonstrates the functionality of the Tool class with a sufficiently detailed description.',
        input_schema: {
          type: 'object',
          properties: {
            param1: { type: 'string' }
          }
        }
      )
      
      expect(tool.name).to eq('test_tool')
      expect(tool.description).to eq('This is a test tool that demonstrates the functionality of the Tool class with a sufficiently detailed description.')
      expect(tool.input_schema).to eq({
        type: 'object',
        properties: {
          param1: { type: 'string' }
        }
      })
    end
    
    it 'creates a tool with parameters (legacy)' do
      tool = described_class.new(
        name: 'test_tool',
        description: 'This is a test tool that demonstrates the functionality of the Tool class with a sufficiently detailed description.',
        parameters: {
          type: 'object',
          properties: {
            param1: { type: 'string' }
          }
        }
      )
      
      expect(tool.input_schema).to eq({
        type: 'object',
        properties: {
          param1: { type: 'string' }
        }
      })
    end
    
    it 'raises an error when name is missing' do
      expect {
        described_class.new(
          name: '',
          description: 'Test description',
          input_schema: { type: 'object' }
        )
      }.to raise_error(ArgumentError, /Tool name is required/)
    end
    
    it 'raises an error when description is missing' do
      expect {
        described_class.new(
          name: 'test_tool',
          description: '',
          input_schema: { type: 'object' }
        )
      }.to raise_error(ArgumentError, /Tool description is required/)
    end
    
    it 'raises an error when input_schema is missing' do
      expect {
        described_class.new(
          name: 'test_tool',
          description: 'Test description'
        )
      }.to raise_error(ArgumentError, /Tool input_schema is required/)
    end
    
    it 'warns when description is too short' do
      expect {
        described_class.new(
          name: 'test_tool',
          description: 'Short desc',
          input_schema: { type: 'object' }
        )
      }.to output(/Warning: Tool 'test_tool' has a short description/).to_stderr
    end
  end
  
  describe '#to_h' do
    it 'returns a hash representation of the tool' do
      tool = described_class.new(
        name: 'test_tool',
        description: 'This is a test tool that demonstrates the functionality of the Tool class with a sufficiently detailed description.',
        input_schema: {
          type: 'object',
          properties: {
            param1: { type: 'string' }
          }
        }
      )
      
      expect(tool.to_h).to eq({
        name: 'test_tool',
        description: 'This is a test tool that demonstrates the functionality of the Tool class with a sufficiently detailed description.',
        input_schema: {
          type: 'object',
          properties: {
            param1: { type: 'string' }
          }
        }
      })
    end
  end
  
  describe '#call' do
    it 'calls the implementation with the provided parameters' do
      tool = described_class.new(
        name: 'test_tool',
        description: 'This is a test tool that demonstrates the functionality of the Tool class with a sufficiently detailed description.',
        input_schema: { type: 'object' }
      ) do |params|
        "Result: #{params['value']}"
      end
      
      result = tool.call({ 'value' => 'test' })
      expect(result).to eq('Result: test')
    end
    
    it 'raises NotImplementedError when no implementation is provided' do
      tool = described_class.new(
        name: 'test_tool',
        description: 'This is a test tool that demonstrates the functionality of the Tool class with a sufficiently detailed description.',
        input_schema: { type: 'object' }
      )
      
      expect { tool.call({}) }.to raise_error(NotImplementedError, /No implementation provided for tool test_tool/)
    end
  end
end
