require 'logger'

module AnthropicTools
  # The Instrumentation module provides tools for monitoring and debugging
  # AnthropicTools client operations. It includes telemetry points for tracking
  # API usage, performance metrics, and debugging information.
  #
  # @example Enabling debug mode
  #   AnthropicTools.configure do |config|
  #     config.debug = true
  #   end
  #
  # @example Using a custom logger
  #   AnthropicTools.configure do |config|
  #     config.logger = Rails.logger
  #   end
  #
  # @example Adding a custom metrics collector
  #   AnthropicTools.configure do |config|
  #     config.metrics_collector = MyMetricsCollector.new
  #   end
  module Instrumentation
    # Base class for metrics collectors
    class MetricsCollector
      # Record a request
      # @param method [Symbol] The HTTP method
      # @param path [String] The request path
      # @param status [Integer] The response status code
      # @param duration [Float] The request duration in seconds
      def record_request(method:, path:, status:, duration:)
        # Override in subclasses
      end

      # Record token usage
      # @param input_tokens [Integer] The number of input tokens
      # @param output_tokens [Integer] The number of output tokens
      def record_token_usage(input_tokens:, output_tokens:)
        # Override in subclasses
      end

      # Record a tool usage
      # @param tool_name [String] The name of the tool
      # @param duration [Float] The tool execution duration in seconds
      def record_tool_usage(tool_name:, duration:)
        # Override in subclasses
      end
    end

    # Null metrics collector that does nothing
    class NullMetricsCollector < MetricsCollector
      def record_request(method:, path:, status:, duration:)
        # Do nothing
      end

      def record_request_start(method:, path:)
        # Do nothing
      end

      def record_token_usage(input_tokens:, output_tokens:)
        # Do nothing
      end

      def record_tool_usage(tool_name:, duration:)
        # Do nothing
      end
    end

    # Logger-based metrics collector that logs metrics
    class LoggerMetricsCollector < MetricsCollector
      # Initialize the logger metrics collector
      # @param logger [Logger] The logger to use
      # @param level [Symbol] The log level to use
      def initialize(logger: Logger.new(STDOUT), level: :info)
        @logger = logger
        @level = level
      end

      # Record a request
      # @param method [Symbol] The HTTP method
      # @param path [String] The request path
      # @param status [Integer] The response status code
      # @param duration [Float] The request duration in seconds
      def record_request(method:, path:, status:, duration:)
        @logger.send(@level, "AnthropicTools Request: #{method.upcase} #{path} - Status: #{status} - Duration: #{duration.round(2)}s")
      end

      # Record token usage
      # @param input_tokens [Integer] The number of input tokens
      # @param output_tokens [Integer] The number of output tokens
      def record_token_usage(input_tokens:, output_tokens:)
        @logger.send(@level, "AnthropicTools Token Usage: Input: #{input_tokens} - Output: #{output_tokens} - Total: #{input_tokens + output_tokens}")
      end

      # Record a tool usage
      # @param tool_name [String] The name of the tool
      # @param duration [Float] The tool execution duration in seconds
      def record_tool_usage(tool_name:, duration:)
        @logger.send(@level, "AnthropicTools Tool Usage: #{tool_name} - Duration: #{duration.round(2)}s")
      end
    end

    # Statsd metrics collector that sends metrics to Statsd
    class StatsdMetricsCollector < MetricsCollector
      # Initialize the Statsd metrics collector
      # @param statsd [Statsd] The Statsd client to use
      # @param prefix [String] The prefix to use for metrics
      def initialize(statsd, prefix: 'anthropic_tools')
        @statsd = statsd
        @prefix = prefix
      end

      # Record a request
      # @param method [Symbol] The HTTP method
      # @param path [String] The request path
      # @param status [Integer] The response status code
      # @param duration [Float] The request duration in seconds
      def record_request(method:, path:, status:, duration:)
        # Record request count
        @statsd.increment("#{@prefix}.request.count", tags: ["method:#{method}", "path:#{path}", "status:#{status}"])
        
        # Record request duration
        @statsd.histogram("#{@prefix}.request.duration", duration, tags: ["method:#{method}", "path:#{path}", "status:#{status}"])
      end

      # Record token usage
      # @param input_tokens [Integer] The number of input tokens
      # @param output_tokens [Integer] The number of output tokens
      def record_token_usage(input_tokens:, output_tokens:)
        @statsd.histogram("#{@prefix}.tokens.input", input_tokens)
        @statsd.histogram("#{@prefix}.tokens.output", output_tokens)
        @statsd.histogram("#{@prefix}.tokens.total", input_tokens + output_tokens)
      end

      # Record a tool usage
      # @param tool_name [String] The name of the tool
      # @param duration [Float] The tool execution duration in seconds
      def record_tool_usage(tool_name:, duration:)
        @statsd.increment("#{@prefix}.tool.count", tags: ["tool:#{tool_name}"])
        @statsd.histogram("#{@prefix}.tool.duration", duration, tags: ["tool:#{tool_name}"])
      end
    end

    # Prometheus metrics collector that sends metrics to Prometheus
    class PrometheusMetricsCollector < MetricsCollector
      # Initialize the Prometheus metrics collector
      # @param registry [Prometheus::Client::Registry] The Prometheus registry to use
      # @param prefix [String] The prefix to use for metrics
      def initialize(registry, prefix: 'anthropic_tools')
        @prefix = prefix
        
        # Create metrics
        @request_counter = registry.counter(
          :"#{@prefix}_requests_total",
          docstring: 'Total number of AnthropicTools requests',
          labels: [:method, :path, :status]
        )
        
        @request_duration = registry.histogram(
          :"#{@prefix}_request_duration_seconds",
          docstring: 'Duration of AnthropicTools requests',
          labels: [:method, :path, :status]
        )
        
        @token_counter = registry.counter(
          :"#{@prefix}_tokens_total",
          docstring: 'Total number of tokens used',
          labels: [:type]
        )
        
        @tool_counter = registry.counter(
          :"#{@prefix}_tool_usage_total",
          docstring: 'Total number of tool usages',
          labels: [:tool]
        )
        
        @tool_duration = registry.histogram(
          :"#{@prefix}_tool_duration_seconds",
          docstring: 'Duration of tool executions',
          labels: [:tool]
        )
      end

      # Record a request
      # @param method [Symbol] The HTTP method
      # @param path [String] The request path
      # @param status [Integer] The response status code
      # @param duration [Float] The request duration in seconds
      def record_request(method:, path:, status:, duration:)
        @request_counter.increment(labels: { method: method, path: path, status: status })
        @request_duration.observe(duration, labels: { method: method, path: path, status: status })
      end

      # Record token usage
      # @param input_tokens [Integer] The number of input tokens
      # @param output_tokens [Integer] The number of output tokens
      def record_token_usage(input_tokens:, output_tokens:)
        @token_counter.increment(by: input_tokens, labels: { type: 'input' })
        @token_counter.increment(by: output_tokens, labels: { type: 'output' })
        @token_counter.increment(by: input_tokens + output_tokens, labels: { type: 'total' })
      end

      # Record a tool usage
      # @param tool_name [String] The name of the tool
      # @param duration [Float] The tool execution duration in seconds
      def record_tool_usage(tool_name:, duration:)
        @tool_counter.increment(labels: { tool: tool_name })
        @tool_duration.observe(duration, labels: { tool: tool_name })
      end
    end
  end
end
