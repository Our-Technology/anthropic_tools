require 'spec_helper'
require 'vcr'

RSpec.describe "Token Counting" do
  let(:config) do
    AnthropicTools::Configuration.new.tap do |c|
      c.api_key = ENV['ANTHROPIC_API_KEY'] || 'test_api_key'
    end
  end
  let(:client) { AnthropicTools::Client.new(config) }
  let(:messages) { [{ role: 'user', content: 'Hello, Claude!' }] }

  before do
    # Reset configuration before each test
    AnthropicTools.reset
    AnthropicTools.configure do |c|
      c.api_key = ENV['ANTHROPIC_API_KEY'] || 'test_api_key'
    end
  end

  describe '#count_tokens', :vcr do
    it 'returns token count information', vcr: { cassette_name: 'token_counting/basic' } do
      result = client.count_tokens(messages)
      
      expect(result).to include(:input_tokens)
      expect(result[:input_tokens]).to be_a(Integer)
      expect(result[:input_tokens]).to be > 0
      expect(result[:_request_id]).to be_a(String)
    end

    it 'includes tools in token count', vcr: { cassette_name: 'token_counting/with_tools' } do
      tools = [
        AnthropicTools::Tool.new(
          name: 'get_weather',
          description: 'Get detailed weather information for a specific location, including current conditions, forecast, and any weather alerts',
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
        )
      ]

      result = client.count_tokens(messages, tools: tools)
      
      expect(result).to include(:input_tokens)
      expect(result[:input_tokens]).to be_a(Integer)
      # Tools should increase token count
      expect(result[:input_tokens]).to be > 0
    end

    it 'includes system prompt in token count', vcr: { cassette_name: 'token_counting/with_system' } do
      system = 'You are a helpful assistant.'
      
      result = client.count_tokens(messages, system: system)
      
      expect(result).to include(:input_tokens)
      expect(result[:input_tokens]).to be_a(Integer)
      expect(result[:input_tokens]).to be > 0
    end

    context 'with error responses' do
      it 'handles errors properly', vcr: { cassette_name: 'token_counting/error_response' } do
        # We'll use a deliberately invalid model to trigger an error
        config.model = 'invalid-model'
        
        expect { client.count_tokens(messages) }.to raise_error(AnthropicTools::NotFoundError)
      end
    end
  end
end
