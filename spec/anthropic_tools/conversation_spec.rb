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
          kind_of(Array),
          hash_including(tools: [], system: nil)
        ).and_return({
          content: 'Hello there!',
          content_blocks: [{ 'type' => 'text', 'text' => 'Hello there!' }],
          role: 'assistant'
        })

        response = conversation.send(message)
        
        expect(response[:content]).to eq('Hello there!')
        expect(conversation.messages.size).to eq(2)
        expect(conversation.messages.first.role).to eq('user')
        expect(conversation.messages.first.content).to eq(message)
        expect(conversation.messages.last.role).to eq('assistant')
        expect(conversation.messages.last.content).to eq([{ 'type' => 'text', 'text' => 'Hello there!' }])
      end
    end

    context 'with tool use' do
      let(:weather_tool) do
        AnthropicTools::Tool.new(
          name: 'get_weather',
          description: 'Get weather information for a specific location. This tool returns the current weather conditions including temperature and general conditions like sunny, cloudy, or rainy.',
          input_schema: {
            type: 'object',
            properties: {
              location: { 
                type: 'string',
                description: 'The city and state, e.g. San Francisco, CA'
              }
            },
            required: ['location']
          }
        ) do |params|
          { temperature: 22, conditions: 'Sunny' }
        end
      end

      it 'processes tool calls and sends a follow-up message' do
        tool_use = AnthropicTools::ToolUse.new({
          'type' => 'tool_use',
          'tool_use' => {
            'id' => 'tool_123',
            'name' => 'get_weather',
            'input' => { 'location' => 'New York' }
          }
        })

        # First response with tool use
        expect(client).to receive(:chat).with(
          kind_of(Array),
          hash_including(tools: [weather_tool], system: nil)
        ).and_return({
          content: 'I\'ll check the weather for you.',
          content_blocks: [
            { 'type' => 'text', 'text' => 'I\'ll check the weather for you.' },
            { 
              'type' => 'tool_use',
              'tool_use' => {
                'id' => 'tool_123',
                'name' => 'get_weather',
                'input' => { 'location' => 'New York' }
              }
            }
          ],
          role: 'assistant',
          tool_calls: [tool_use]
        })

        # Follow-up response after tool use
        expect(client).to receive(:chat).with(
          kind_of(Array),  # We don't need to check the exact messages
          hash_including(tools: [weather_tool], system: nil)
        ).and_return({
          content: 'The weather in New York is sunny and 22 degrees.',
          content_blocks: [{ 'type' => 'text', 'text' => 'The weather in New York is sunny and 22 degrees.' }],
          role: 'assistant'
        })

        conversation.add_tools(weather_tool)
        response = conversation.send(message)
        
        expect(response[:content]).to eq('The weather in New York is sunny and 22 degrees.')
        expect(conversation.messages.size).to eq(4)  # user, assistant with tool, user with tool results, final assistant
      end
      
      it 'supports tool_choice parameter' do
        expect(client).to receive(:chat).with(
          kind_of(Array),
          hash_including(
            tools: [weather_tool], 
            system: nil,
            tool_choice: { type: 'any' }
          )
        ).and_return({
          content: 'Hello there!',
          content_blocks: [{ 'type' => 'text', 'text' => 'Hello there!' }],
          role: 'assistant'
        })

        conversation.add_tools(weather_tool)
        response = conversation.send(message, tool_choice: { type: 'any' })
        
        expect(response[:content]).to eq('Hello there!')
      end
      
      it 'supports disable_parallel_tool_use parameter' do
        expect(client).to receive(:chat).with(
          kind_of(Array),
          hash_including(
            tools: [weather_tool], 
            system: nil,
            disable_parallel_tool_use: true
          )
        ).and_return({
          content: 'Hello there!',
          content_blocks: [{ 'type' => 'text', 'text' => 'Hello there!' }],
          role: 'assistant'
        })

        conversation.add_tools(weather_tool)
        response = conversation.send(message, disable_parallel_tool_use: true)
        
        expect(response[:content]).to eq('Hello there!')
      end
    end
  end
end
