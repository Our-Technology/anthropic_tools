require 'spec_helper'

RSpec.describe AnthropicTools::Configuration do
  let(:config) { described_class.new }

  describe 'default values' do
    it 'has default values for timeout and retry settings' do
      expect(config.timeout).to be_a(Numeric)
      expect(config.max_retries).to be_a(Integer)
      expect(config.retry_initial_delay).to be_a(Numeric)
      expect(config.retry_max_delay).to be_a(Numeric)
      expect(config.retry_jitter).to be_a(Numeric)
      expect(config.retry_statuses).to be_an(Array)
    end
  end

  describe 'configuration options' do
    it 'allows setting timeout' do
      config.timeout = 120
      expect(config.timeout).to eq(120)
    end

    it 'allows setting max_retries' do
      config.max_retries = 5
      expect(config.max_retries).to eq(5)
    end

    it 'allows setting retry_initial_delay' do
      config.retry_initial_delay = 2.0
      expect(config.retry_initial_delay).to eq(2.0)
    end

    it 'allows setting retry_max_delay' do
      config.retry_max_delay = 10.0
      expect(config.retry_max_delay).to eq(10.0)
    end

    it 'allows setting retry_jitter' do
      config.retry_jitter = 0.5
      expect(config.retry_jitter).to eq(0.5)
    end

    it 'allows setting retry_statuses' do
      config.retry_statuses = [429, 500, 503]
      expect(config.retry_statuses).to eq([429, 500, 503])
    end
  end

  describe '#calculate_timeout' do
    it 'returns the minimum timeout when max_tokens is nil' do
      config.timeout = 30
      expect(config.calculate_timeout).to eq(600) # Minimum timeout is 600 seconds
    end

    it 'calculates a timeout based on max_tokens' do
      config.timeout = 30
      
      # With a large number of tokens, timeout should be increased
      large_timeout = config.calculate_timeout(128000)
      
      # With a small number of tokens, timeout should be the minimum
      small_timeout = config.calculate_timeout(100)
      
      expect(large_timeout).to be > small_timeout
      expect(small_timeout).to eq(600) # Minimum timeout is 600 seconds
    end

    it 'applies a minimum timeout' do
      config.timeout = 5
      
      # Even with 0 tokens, there should be a minimum timeout
      expect(config.calculate_timeout(0)).to eq(600) # Minimum timeout is 600 seconds
    end
  end

  describe 'global configuration' do
    before do
      AnthropicTools.reset
    end

    it 'allows configuring through the module' do
      AnthropicTools.configure do |c|
        c.api_key = 'test_key'
        c.timeout = 60
        c.max_retries = 4
      end

      expect(AnthropicTools.configuration.api_key).to eq('test_key')
      expect(AnthropicTools.configuration.timeout).to eq(60)
      expect(AnthropicTools.configuration.max_retries).to eq(4)
    end

    it 'provides access to the configuration' do
      AnthropicTools.configure do |c|
        c.api_key = 'test_key'
      end

      expect(AnthropicTools.configuration).to be_a(AnthropicTools::Configuration)
      expect(AnthropicTools.configuration.api_key).to eq('test_key')
    end
  end
end
