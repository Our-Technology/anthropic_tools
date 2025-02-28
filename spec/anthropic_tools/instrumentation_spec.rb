require 'spec_helper'

RSpec.describe AnthropicTools::Instrumentation do
  describe AnthropicTools::Instrumentation::LoggerMetricsCollector do
    let(:logger) { instance_double(Logger) }
    let(:collector) { described_class.new(logger: logger) }
    
    it "logs request metrics" do
      expect(logger).to receive(:info).with(/AnthropicTools Request: POST \/test - Status: 200 - Duration: 1.0s/)
      
      collector.record_request(
        method: :post,
        path: '/test',
        status: 200,
        duration: 1.0
      )
    end
    
    it "logs token usage" do
      expect(logger).to receive(:info).with(/AnthropicTools Token Usage: Input: 10 - Output: 20 - Total: 30/)
      
      collector.record_token_usage(
        input_tokens: 10,
        output_tokens: 20
      )
    end
    
    it "logs tool usage" do
      expect(logger).to receive(:info).with(/AnthropicTools Tool Usage: test_tool - Duration: 0.5s/)
      
      collector.record_tool_usage(
        tool_name: 'test_tool',
        duration: 0.5
      )
    end
  end
  
  describe "Configuration integration" do
    after do
      AnthropicTools.reset
    end
    
    it "creates a NullMetricsCollector by default" do
      expect(AnthropicTools.configuration.metrics_collector).to be_a(AnthropicTools::Instrumentation::NullMetricsCollector)
    end
    
    it "creates a LoggerMetricsCollector when debug is enabled" do
      AnthropicTools.configure do |config|
        config.debug = true
      end
      
      expect(AnthropicTools.configuration.metrics_collector).to be_a(AnthropicTools::Instrumentation::LoggerMetricsCollector)
    end
    
    it "allows setting a custom metrics collector" do
      custom_collector = AnthropicTools::Instrumentation::LoggerMetricsCollector.new
      
      AnthropicTools.configure do |config|
        config.metrics_collector = custom_collector
      end
      
      expect(AnthropicTools.configuration.metrics_collector).to eq(custom_collector)
    end
  end
end
