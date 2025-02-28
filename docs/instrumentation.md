# AnthropicTools Instrumentation

AnthropicTools includes instrumentation for monitoring API usage and performance metrics. This allows you to track request/response metrics, token usage, and tool usage across your application.

## How Instrumentation Works

The instrumentation system in AnthropicTools is built around metrics collectors:

1. Each metrics collector implements methods to record different types of metrics:
   - `record_request`: Records information about API requests and responses
   - `record_token_usage`: Records token consumption for input and output
   - `record_tool_usage`: Records information about tool usage

2. Metrics collectors can be configured globally or per-client
3. The default `NullMetricsCollector` does nothing, ensuring zero overhead when metrics aren't needed

## Built-in Metrics Collectors

AnthropicTools comes with several built-in metrics collectors:

### NullMetricsCollector

The default collector that does nothing. Used when metrics collection is not needed:

```ruby
# This is the default, so you don't need to set it explicitly
AnthropicTools.configure do |config|
  config.metrics_collector = AnthropicTools::Instrumentation::NullMetricsCollector.new
end
```

### LoggerMetricsCollector

Logs metrics information to a logger:

```ruby
# Enable debug mode to use the LoggerMetricsCollector with Rails.logger
AnthropicTools.configure do |config|
  config.debug = true
end

# Or set a specific logger and log level
AnthropicTools.configure do |config|
  config.metrics_collector = AnthropicTools::Instrumentation::LoggerMetricsCollector.new(
    logger: Rails.logger,
    level: :info
  )
end
```

Example log output:
```
[2025-02-28T17:10:23] INFO: AnthropicTools API Request: POST /v1/messages (Status: 200, Duration: 1.85s)
[2025-02-28T17:10:23] INFO: AnthropicTools Token Usage: 125 input tokens, 348 output tokens (473 total)
[2025-02-28T17:10:23] INFO: AnthropicTools Tool Usage: get_weather (Duration: 0.12s)
```

## Creating Custom Metrics Collectors

You can create custom metrics collectors by inheriting from `AnthropicTools::Instrumentation::MetricsCollector`:

```ruby
# Create a custom metrics collector for StatsD
class StatsdMetricsCollector < AnthropicTools::Instrumentation::MetricsCollector
  def initialize(statsd_client)
    @statsd = statsd_client
  end

  def record_request(method:, path:, status:, duration:)
    @statsd.timing('anthropic.request.duration', duration * 1000)
    @statsd.increment('anthropic.request.count', tags: ["status:#{status}"])
  end

  def record_token_usage(input_tokens:, output_tokens:)
    @statsd.gauge('anthropic.tokens.input', input_tokens)
    @statsd.gauge('anthropic.tokens.output', output_tokens)
    @statsd.gauge('anthropic.tokens.total', input_tokens + output_tokens)
  end

  def record_tool_usage(tool_name:, duration:)
    @statsd.timing('anthropic.tool.duration', duration * 1000, tags: ["tool:#{tool_name}"])
    @statsd.increment('anthropic.tool.count', tags: ["tool:#{tool_name}"])
  end
end

# Add it to the configuration
AnthropicTools.configure do |config|
  statsd = Datadog::Statsd.new('localhost', 8125)
  config.metrics_collector = StatsdMetricsCollector.new(statsd)
end
```

## Combining with Middleware

Instrumentation works well with middleware. The built-in `Metrics` middleware uses the configured metrics collector:

```ruby
AnthropicTools.configure do |config|
  # Set up a metrics collector
  config.metrics_collector = AnthropicTools::Instrumentation::LoggerMetricsCollector.new(
    logger: Rails.logger
  )
  
  # Add the metrics middleware
  config.add_middleware(AnthropicTools::Middleware::Metrics.new(config.metrics_collector))
end
```

## Best Practices

1. **Choose the right collector**: Use the appropriate metrics collector for your monitoring needs.

2. **Monitor token usage**: Token usage directly impacts costs, so it's important to track.

3. **Track tool usage**: If you're using tools, monitoring their usage can help identify performance bottlenecks.

4. **Aggregate metrics**: For production systems, consider sending metrics to a centralized system like Datadog, Prometheus, or CloudWatch.

5. **Set appropriate sampling**: For high-traffic applications, consider sampling metrics to reduce overhead.

## Implementation Details

### MetricsCollector Base Class

The `AnthropicTools::Instrumentation::MetricsCollector` class provides the foundation for all metrics collectors:

```ruby
module AnthropicTools
  module Instrumentation
    class MetricsCollector
      def record_request_start(method:, path:)
        # Optional: record the start of a request
      end

      def record_request(method:, path:, status:, duration:)
        # Record information about a completed request
      end

      def record_token_usage(input_tokens:, output_tokens:)
        # Record token usage information
      end

      def record_tool_usage(tool_name:, duration:)
        # Record information about tool usage
      end
    end
  end
end
```

## Testing Metrics Collectors

Here's an example of how to test custom metrics collectors:

```ruby
RSpec.describe StatsdMetricsCollector do
  let(:statsd) { instance_double(Datadog::Statsd) }
  let(:collector) { StatsdMetricsCollector.new(statsd) }
  
  describe "#record_request" do
    it "records request metrics" do
      expect(statsd).to receive(:timing).with('anthropic.request.duration', 1850.0)
      expect(statsd).to receive(:increment).with('anthropic.request.count', tags: ["status:200"])
      
      collector.record_request(
        method: :post,
        path: '/v1/messages',
        status: 200,
        duration: 1.85
      )
    end
  end
  
  # Additional tests for token_usage and tool_usage...
end
```
