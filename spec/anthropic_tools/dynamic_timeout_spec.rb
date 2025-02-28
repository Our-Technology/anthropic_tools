require 'spec_helper'

RSpec.describe "Dynamic Timeout" do
  let(:config) do
    AnthropicTools::Configuration.new.tap do |c|
      c.api_key = ENV['ANTHROPIC_API_KEY'] || 'test_api_key'
    end
  end
  let(:client) { AnthropicTools::Client.new(config) }
  let(:messages) { [{ role: 'user', content: 'Write a one-paragraph summary of Ruby on Rails.' }] }

  describe '#calculate_timeout' do
    it 'returns the minimum timeout when max_tokens is nil' do
      timeout = config.calculate_timeout(nil)
      expect(timeout).to eq(600) # Minimum timeout is 600 seconds (10 minutes)
    end

    it 'calculates a timeout based on max_tokens' do
      # Use a large number of tokens that would calculate to more than the minimum
      max_tokens = 30000
      timeout = config.calculate_timeout(max_tokens)
      
      # Expected calculation: (60 * 60 * max_tokens) / 128_000.0
      expected_timeout = (60 * 60 * max_tokens) / 128_000.0
      
      expect(timeout).to eq(expected_timeout)
    end

    it 'applies a minimum timeout' do
      # Use a small number of tokens that would calculate to less than the minimum
      small_tokens = 1000
      timeout = config.calculate_timeout(small_tokens)
      
      calculated = (60 * 60 * small_tokens) / 128_000.0
      expect(calculated).to be < 600 # Should be less than minimum
      expect(timeout).to eq(600) # Should return minimum
    end
  end

  describe 'dynamic timeout with large max_tokens', :vcr do
    it 'successfully completes a request with a large max_tokens value', 
       vcr: { cassette_name: 'dynamic_timeout/large_max_tokens' } do
      
      # Set a large max_tokens value to trigger dynamic timeout
      large_max_tokens = 4000
      
      # Calculate the expected timeout
      expected_timeout = config.calculate_timeout(large_max_tokens)
      
      # The timeout should be larger than the default
      expect(expected_timeout).to be > config.timeout
      
      # Make the request with the large max_tokens value
      result = client.chat(messages, max_tokens: large_max_tokens)
      
      # Verify the response
      expect(result).to include(:content)
      expect(result[:content]).not_to be_empty
      expect(result[:usage]).to include('input_tokens')
      expect(result[:usage]).to include('output_tokens')
    end
  end
end
