require 'spec_helper'
require 'webmock/rspec'

RSpec.describe AnthropicTools::Client do
  let(:config) do
    AnthropicTools::Configuration.new.tap do |c|
      c.api_key = ENV['ANTHROPIC_API_KEY'] || 'test_api_key'
    end
  end
  let(:client) { described_class.new(config) }

  before do
    # Reset configuration before each test
    AnthropicTools.reset
    AnthropicTools.configure do |c|
      c.api_key = ENV['ANTHROPIC_API_KEY'] || 'test_api_key'
    end
  end

  describe '#chat' do
    let(:message) { { role: 'user', content: 'Hello' } }

    context 'with a basic message' do
      it 'returns the expected response', vcr: { cassette_name: 'client/basic_message' } do
        result = client.chat(message)
        
        expect(result[:content]).to be_a(String)
        expect(result[:content]).not_to be_empty
        expect(result[:role]).to eq('assistant')
        expect(result[:id]).to be_a(String)
      end
    end

    context 'with tool use' do
      let(:tool) { AnthropicTools::Tool.new(name: 'get_weather', description: 'Get weather information for a specific location. This tool returns the current weather conditions including temperature and general conditions like sunny, cloudy, or rainy.', input_schema: { type: 'object', properties: { location: { type: 'string', description: 'The city and state, e.g. San Francisco, CA' } }, required: ['location'] }) }
      
      it 'extracts tool calls from the response' do
        # Create a test double for the connection
        connection = instance_double(Faraday::Connection)
        allow(client).to receive(:connection).and_return(connection)
        
        # Set up expectations for the API call
        expect(connection).to receive(:post) do |url, payload|
          expect(url).to eq('/v1/messages')
          expect(payload).to have_key('tools')
          
          # Return a response with a tool call
          double('response', 
            status: 200, 
            headers: { 'x-request-id' => 'req_123' },
            body: {
              content: [{ type: 'tool_use', id: 'tool_use_1', name: 'get_weather', input: { location: 'San Francisco, CA' } }],
              id: 'msg_123',
              model: 'claude-3-7-sonnet-20250219',
              role: 'assistant',
              type: 'message'
            }.to_json
          )
        end
        
        # Call the method
        response = client.chat(message, tools: [tool])
        
        # Verify that the tool calls are extracted
        expect(response[:tool_calls].length).to eq(1)
        expect(response[:tool_calls][0].name).to eq('get_weather')
        expect(response[:tool_calls][0].input).to eq({ "location" => "San Francisco, CA" })
      end
      
      it 'supports tool_choice parameter' do
        # Create a test double for the connection
        connection = instance_double(Faraday::Connection)
        allow(client).to receive(:connection).and_return(connection)
        
        # Set up expectations for the API call
        expect(connection).to receive(:post) do |url, payload|
          expect(url).to eq('/v1/messages')
          expect(payload['tool_choice']).to eq({ 'type' => 'any' })
          
          # Return a simple response
          double('response', 
            status: 200, 
            headers: { 'x-request-id' => 'req_123' },
            body: {
              content: [{ type: 'text', text: 'Hello' }],
              id: 'msg_123',
              model: 'claude-3-7-sonnet-20250219',
              role: 'assistant',
              type: 'message'
            }.to_json
          )
        end
        
        # Call the method
        client.chat(message, tools: [tool], tool_choice: { type: 'any' })
      end
      
      it 'supports disable_parallel_tool_use parameter' do
        # Create a test double for the connection
        connection = instance_double(Faraday::Connection)
        allow(client).to receive(:connection).and_return(connection)
        
        # Set up expectations for the API call
        expect(connection).to receive(:post) do |url, payload|
          expect(url).to eq('/v1/messages')
          expect(payload['tool_choice']).to eq({ 'type' => 'auto', 'disable_parallel_tool_use' => true })
          
          # Return a simple response
          double('response', 
            status: 200, 
            headers: { 'x-request-id' => 'req_123' },
            body: {
              content: [{ type: 'text', text: 'Hello' }],
              id: 'msg_123',
              model: 'claude-3-7-sonnet-20250219',
              role: 'assistant',
              type: 'message'
            }.to_json
          )
        end
        
        # Call the method
        client.chat(message, tools: [tool], disable_parallel_tool_use: true)
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
          allow(req).to receive(:headers=)
          
          expect(req).to receive(:body=) do |body_json|
            body = JSON.parse(body_json, symbolize_names: true)
            expect(body[:stream]).to eq(true)
          end
          
          block.call(req)
          double('response', 
            status: 200, 
            headers: { 'x-request-id' => 'req_123' },
            body: '')
        end
        
        # Call the method
        client.chat(message, stream: true) { |chunk| }
      end
    end
  end
end
