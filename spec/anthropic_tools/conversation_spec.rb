require 'spec_helper'

RSpec.describe AnthropicTools::Conversation do
  let(:client) { instance_double(AnthropicTools::Client) }
  let(:conversation) { described_class.new(client) }

  describe '#send' do
    let(:tools) { [] }
    let(:message) { 'Hello, Claude!' }

    context 'with a simple response' do
      it 'adds messages and returns the response' do
        expect(client).to receive(:chat).with(
          [{ role: 'user', content: message }],
          tools: [],
          system: nil
        ).and_return({
          content: 'Hello there!',
          role: 'assistant'
        })

        response = conversation.send(message)
        
        expect(response[:content]).to eq('Hello there!')
        expect(conversation.messages.size).to eq(2)
        expect(conversation.messages.first.role).to eq('user')
        expect(conversation.messages.first.content).to eq(message)
        expect(conversation.messages.last.role).to eq('assistant')
        expect(conversation.messages.last.content).to eq('Hello there!')
      end
    end

    context 'with tool use' do
      let(:weather_tool) do
        AnthropicTools::Tool.new(
          name: 'get_weather',
          description: 'Get weather information',
          parameters: {
            type: 'object',
            properties: {
              location: { type: 'string' }
            },
            required: ['location']
          }
        ) do |params|
          { temperature: 22, conditions: 'Sunny' }
        end
      end

      it 'processes tool calls and sends a follow-up message' do
        tool_use = AnthropicTools::ToolUse.new({
          'id' => 'tool_123',
          'name' => 'get_weather',
          'input' => { 'location' => 'New York' }
        })

        # First response with tool use
        expect(client).to receive(:chat).with(
          [{ role: 'user', content: message }],
          tools: [weather_tool],
          system: nil
        ).and_return({
          content: 'I\'ll check the weather for you.',
          role: 'assistant',
          tool_calls: [tool_use]
        })

        # Follow-up response after tool use
        expect(client).to receive(:chat).with(
          kind_of(Array),  # We don't need to check the exact messages
          tools: [weather_tool],
          system: nil
        ).and_return({
          content: 'The weather in New York is sunny and 22 degrees.',
          role: 'assistant'
        })

        conversation.add_tools(weather_tool)
        response = conversation.send(message)
        
        expect(response[:content]).to eq('The weather in New York is sunny and 22 degrees.')
        expect(conversation.messages.size).to eq(3)  # user, assistant with tool, final assistant
      end
    end
  end
end
