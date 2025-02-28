require 'spec_helper'
require 'webmock/rspec'

RSpec.describe AnthropicTools::Client do
  let(:config) do
    AnthropicTools::Configuration.new.tap do |c|
      c.api_key = 'test_api_key'
    end
  end
  let(:client) { described_class.new(config) }

  before do
    # Reset configuration before each test
    AnthropicTools.reset
    AnthropicTools.configure do |c|
      c.api_key = 'test_api_key'
    end
  end

  describe '#chat' do
    let(:message) { { role: 'user', content: 'Hello' } }

    context 'with a basic message' do
      it 'returns the expected response' do
        response_body = {
          'id' => 'msg_12345',
          'model' => 'claude-3-7-sonnet-20250219',
          'role' => 'assistant',
          'content' => [{ 'type' => 'text', 'text' => 'Hello there!' }],
          'stop_reason' => 'end_turn',
          'usage' => { 'input_tokens' => 10, 'output_tokens' => 5 }
        }

        stub_anthropic_api(response_body)
        
        result = client.chat(message)
        
        expect(result[:content]).to eq('Hello there!')
        expect(result[:role]).to eq('assistant')
        expect(result[:id]).to eq('msg_12345')
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
        )
      end

      it 'extracts tool calls from the response' do
        response_body = {
          'id' => 'msg_12345',
          'model' => 'claude-3-7-sonnet-20250219',
          'role' => 'assistant',
          'content' => [
            { 'type' => 'text', 'text' => 'I\'ll check the weather for you.' },
            { 
              'type' => 'tool_use',
              'tool_use' => {
                'id' => 'call_12345',
                'name' => 'get_weather',
                'input' => { 'location' => 'New York' }
              }
            }
          ]
        }
        
        stub_anthropic_api(response_body)
        
        result = client.chat(message, tools: [weather_tool])
        
        expect(result[:tool_calls]).not_to be_nil
        expect(result[:tool_calls]).not_to be_empty
        expect(result[:tool_calls].first).to be_a(AnthropicTools::ToolUse)
        expect(result[:tool_calls].first.name).to eq('get_weather')
        expect(result[:tool_calls].first.input).to eq({ 'location' => 'New York' })
      end
    end

    context 'with errors' do
      it 'raises an authentication error for 401 responses' do
        stub_anthropic_api({ 'error' => { 'message' => 'Invalid API key' } }, status: 401)
        
        expect { client.chat(message) }.to raise_error(AnthropicTools::AuthenticationError)
      end

      it 'raises a rate limit error for 429 responses' do
        stub_anthropic_api({ 'error' => { 'message' => 'Rate limit exceeded' } }, status: 429)
        
        expect { client.chat(message) }.to raise_error(AnthropicTools::RateLimitError)
      end
    end

    context 'with streaming' do
      it 'sets the stream parameter to true' do
        # Create a test double for the connection
        connection = instance_double(Faraday::Connection)
        allow(client).to receive(:connection).and_return(connection)
        
        # Set up expectations
        expect(connection).to receive(:post).with('/v1/messages') do |&block|
          req = double('request')
          options = double('options')
          allow(req).to receive(:options).and_return(options)
          allow(options).to receive(:on_data=)
          
          expect(req).to receive(:body=) do |body_json|
            body = JSON.parse(body_json)
            expect(body['stream']).to eq(true)
          end
          
          block.call(req)
          double('response', status: 200, body: '')
        end
        
        # Call the method
        client.chat(message, stream: true) { |chunk| }
      end
    end
  end
end
