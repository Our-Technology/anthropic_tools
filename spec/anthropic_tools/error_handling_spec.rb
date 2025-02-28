require 'spec_helper'
require 'webmock/rspec'

RSpec.describe "Error Handling" do
  let(:config) do
    AnthropicTools::Configuration.new.tap do |c|
      c.api_key = ENV['ANTHROPIC_API_KEY'] || 'test_api_key'
    end
  end
  let(:client) { AnthropicTools::Client.new(config) }
  let(:message) { [{ role: 'user', content: 'Hello' }] }

  before do
    # Reset configuration before each test
    AnthropicTools.reset
    AnthropicTools.configure do |c|
      c.api_key = ENV['ANTHROPIC_API_KEY'] || 'test_api_key'
    end
  end

  context 'with API errors' do
    it 'raises BadRequestError for 400 responses', vcr: { cassette_name: 'error_handling/bad_request_error' } do
      # Set an invalid parameter to trigger a 400 error
      invalid_message = []  # Empty messages array will cause a validation error
      
      expect { client.chat(invalid_message) }.to raise_error(AnthropicTools::BadRequestError) do |error|
        expect(error.status_code).to eq(400)
        expect(error.request_id).to be_a(String)
      end
    end

    it 'raises AuthenticationError for 401 responses', vcr: { cassette_name: 'error_handling/authentication_error' } do
      # Temporarily set an invalid API key
      config.api_key = 'invalid_api_key'
      
      expect { client.chat(message) }.to raise_error(AnthropicTools::AuthenticationError) do |error|
        expect(error.status_code).to eq(401)
        expect(error.request_id).to be_a(String)
      end
    end

    # For the remaining error tests, we'll use WebMock stubs since it's difficult to trigger
    # these errors consistently with real API calls
    
    it 'raises PermissionDeniedError for 403 responses' do
      stub_request(:post, "https://api.anthropic.com/v1/messages")
        .to_return(
          status: 403,
          body: { error: { message: 'Permission denied', type: 'permission_error' } }.to_json,
          headers: { 'Content-Type' => 'application/json', 'X-Request-ID' => 'req_123' }
        )
      
      expect { client.chat(message) }.to raise_error(AnthropicTools::PermissionDeniedError) do |error|
        expect(error.message).to include('Permission denied')
        expect(error.status_code).to eq(403)
        expect(error.request_id).to eq('req_123')
      end
    end

    it 'raises NotFoundError for 404 responses', vcr: { cassette_name: 'error_handling/not_found_error' } do
      # Use an invalid model to trigger a 404 error
      config.model = 'invalid-model'
      
      expect { client.chat(message) }.to raise_error(AnthropicTools::NotFoundError) do |error|
        expect(error.status_code).to eq(404)
        expect(error.request_id).to be_a(String)
      end
    end

    it 'raises RateLimitError for 429 responses' do
      stub_request(:post, "https://api.anthropic.com/v1/messages")
        .to_return(
          status: 429,
          body: { error: { message: 'Rate limit exceeded', type: 'rate_limit_error' } }.to_json,
          headers: { 'Content-Type' => 'application/json', 'X-Request-ID' => 'req_123' }
        )
      
      expect { client.chat(message) }.to raise_error(AnthropicTools::RateLimitError) do |error|
        expect(error.message).to include('Rate limit exceeded')
        expect(error.status_code).to eq(429)
        expect(error.request_id).to eq('req_123')
      end
    end

    it 'raises ServerError for 500 responses' do
      stub_request(:post, "https://api.anthropic.com/v1/messages")
        .to_return(
          status: 500,
          body: { error: { message: 'Internal server error', type: 'server_error' } }.to_json,
          headers: { 'Content-Type' => 'application/json', 'X-Request-ID' => 'req_123' }
        )
      
      expect { client.chat(message) }.to raise_error(AnthropicTools::ServerError) do |error|
        expect(error.message).to include('Internal server error')
        expect(error.status_code).to eq(500)
        expect(error.request_id).to eq('req_123')
      end
    end
  end

  context 'with connection errors' do
    it 'raises APIConnectionError for network errors' do
      # For this test, we need to simulate a connection error
      allow(client).to receive(:connection).and_raise(Faraday::ConnectionFailed.new('Connection failed'))
      
      expect { client.chat(message) }.to raise_error(AnthropicTools::APIConnectionError) do |error|
        expect(error.message).to include('Connection failed')
      end
    end

    it 'raises APIConnectionTimeoutError for timeout errors' do
      # For this test, we need to simulate a timeout error
      allow(client).to receive(:connection).and_raise(Faraday::TimeoutError.new('Connection timed out'))
      
      expect { client.chat(message) }.to raise_error(AnthropicTools::APIConnectionTimeoutError) do |error|
        expect(error.message).to include('Connection timed out')
      end
    end
  end

  context 'with retry configuration' do
    let(:config) do
      AnthropicTools::Configuration.new.tap do |c|
        c.api_key = ENV['ANTHROPIC_API_KEY'] || 'test_api_key'
        c.max_retries = 2
        c.retry_initial_delay = 0.1
        c.retry_max_delay = 0.2
        c.retry_jitter = 0.1
      end
    end

    it 'retries on retryable status codes' do
      # First two requests fail with 429, third succeeds
      stub_request(:post, "https://api.anthropic.com/v1/messages")
        .to_return(
          { status: 429, body: { error: { message: 'Rate limit exceeded' } }.to_json, headers: { 'Content-Type' => 'application/json' } },
          { status: 429, body: { error: { message: 'Rate limit exceeded' } }.to_json, headers: { 'Content-Type' => 'application/json' } },
          { status: 200, body: { id: 'msg_123', content: [{ type: 'text', text: 'Hello' }] }.to_json, headers: { 'Content-Type' => 'application/json' } }
        )
      
      # Should succeed after retries
      result = client.chat(message)
      expect(result[:content]).to eq('Hello')
    end

    it 'gives up after max retries' do
      # All requests fail with 429
      stub_request(:post, "https://api.anthropic.com/v1/messages")
        .to_return(
          { status: 429, body: { error: { message: 'Rate limit exceeded' } }.to_json, headers: { 'Content-Type' => 'application/json' } },
          { status: 429, body: { error: { message: 'Rate limit exceeded' } }.to_json, headers: { 'Content-Type' => 'application/json' } },
          { status: 429, body: { error: { message: 'Rate limit exceeded' } }.to_json, headers: { 'Content-Type' => 'application/json' } }
        )
      
      # Should fail after max retries
      expect { client.chat(message) }.to raise_error(AnthropicTools::RateLimitError)
    end
  end
end
