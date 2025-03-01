require 'logger'

module AnthropicTools
  # Instrumentation for monitoring API usage and performance
  #
  # The Instrumentation module provides classes for collecting metrics about
  # API requests, responses, and token usage. These metrics can be used for
  # monitoring, debugging, and optimization.
  #
  # @example Using the logger metrics collector
  #   AnthropicTools.configure do |config|
  #     config.metrics_collector = AnthropicTools::Instrumentation::LoggerMetricsCollector.new(
  #       logger: Rails.logger
  #     )
  #   end
  #
  # @example Creating a custom metrics collector
  #   class CustomMetricsCollector < AnthropicTools::Instrumentation::MetricsCollector
  #     def record_request(method:, path:, status:, duration:)
  #       # Send metrics to your monitoring system
  #       StatsD.timing("anthropic.request.duration", duration * 1000)
  #       StatsD.increment("anthropic.request.count", tags: ["status:#{status}"])
  #     end
  #
  #     def record_token_usage(input_tokens:, output_tokens:)
  #       # Record token usage
  #       StatsD.gauge("anthropic.tokens.input", input_tokens)
  #       StatsD.gauge("anthropic.tokens.output", output_tokens)
  #     end
  #   end
  #
  #   AnthropicTools.configure do |config|
  #     config.metrics_collector = CustomMetricsCollector.new
  #   end
  module Instrumentation
    # Base class for metrics collectors
    #
    # The MetricsCollector class defines the interface for collecting metrics
    # about API requests, responses, and token usage. Subclasses should implement
    # the {#record_request} and {#record_token_usage} methods.
    #
    # @abstract Subclass and override {#record_request} and {#record_token_usage} to implement
    class MetricsCollector
      # Record metrics for an API request
      #
      # @param method [Symbol] The HTTP method (:get, :post, etc.)
      # @param path [String] The API endpoint path
      # @param status [Integer] The HTTP status code
      # @param duration [Float] The request duration in seconds
      # @return [void]
      # @abstract
      def record_request(method:, path:, status:, duration:)
        # Implement in subclasses
      end

      # Record metrics for token usage
      #
      # @param input_tokens [Integer] The number of input tokens
      # @param output_tokens [Integer] The number of output tokens
      # @return [void]
      # @abstract
      def record_token_usage(input_tokens:, output_tokens:)
        # Implement in subclasses
      end

      # Record the start of a request
      #
      # This method is optional and may be implemented by subclasses
      # to record metrics at the start of a request.
      #
      # @param method [Symbol] The HTTP method (:get, :post, etc.)
      # @param path [String] The API endpoint path
      # @return [void]
      def record_request_start(method:, path:)
        # Optional method, implement in subclasses if needed
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
    #
    # The NullMetricsCollector is a no-op implementation of the MetricsCollector
    # interface. It can be used when metrics collection is not needed.
    #
    # @example
    #   AnthropicTools.configure do |config|
    #     config.metrics_collector = AnthropicTools::Instrumentation::NullMetricsCollector.new
    #   end
    class NullMetricsCollector < MetricsCollector
      # Record metrics for an API request (no-op)
      #
      # @param method [Symbol] The HTTP method (:get, :post, etc.)
      # @param path [String] The API endpoint path
      # @param status [Integer] The HTTP status code
      # @param duration [Float] The request duration in seconds
      # @return [void]
      def record_request(method:, path:, status:, duration:)
        # No-op
      end

      # Record metrics for token usage (no-op)
      #
      # @param input_tokens [Integer] The number of input tokens
      # @param output_tokens [Integer] The number of output tokens
      # @return [void]
      def record_token_usage(input_tokens:, output_tokens:)
        # No-op
      end

      def record_request_start(method:, path:)
        # Do nothing
      end

      def record_tool_usage(tool_name:, duration:)
        # Do nothing
      end
    end

    # Logger-based metrics collector
    #
    # The LoggerMetricsCollector logs metrics about API requests, responses,
    # and token usage using a logger. It can be used for debugging and monitoring.
    #
    # @example
    #   AnthropicTools.configure do |config|
    #     config.metrics_collector = AnthropicTools::Instrumentation::LoggerMetricsCollector.new(
    #       logger: Rails.logger,
    #       level: :info
    #     )
    #   end
    class LoggerMetricsCollector < MetricsCollector
      # Create a new logger metrics collector
      #
      # @param logger [Logger] The logger to use (defaults to a new Logger instance)
      # @param level [Symbol, String] The log level to use (:debug, :info, :warn, :error, :fatal)
      # @return [LoggerMetricsCollector] A new logger metrics collector instance
      def initialize(logger: nil, level: :info)
        @logger = logger || Logger.new(STDOUT)
        @level = level.to_sym
      end

      # Record metrics for an API request
      #
      # Logs information about the request, including method, path, status, and duration.
      #
      # @param method [Symbol] The HTTP method (:get, :post, etc.)
      # @param path [String] The API endpoint path
      # @param status [Integer] The HTTP status code
      # @param duration [Float] The request duration in seconds
      # @return [void]
      def record_request(method:, path:, status:, duration:)
        @logger.send(@level, "AnthropicTools Request: #{method.to_s.upcase} #{path} - Status: #{status} - Duration: #{duration}s")
      end

      # Record metrics for token usage
      #
      # Logs information about token usage, including input and output tokens.
      #
      # @param input_tokens [Integer] The number of input tokens
      # @param output_tokens [Integer] The number of output tokens
      # @return [void]
      def record_token_usage(input_tokens:, output_tokens:)
        @logger.send(@level, "AnthropicTools Token Usage: Input: #{input_tokens} - Output: #{output_tokens} - Total: #{input_tokens + output_tokens}")
      end

      # Record the start of a request
      #
      # Logs information about the start of a request, including method and path.
      #
      # @param method [Symbol] The HTTP method (:get, :post, etc.)
      # @param path [String] The API endpoint path
      # @return [void]
      def record_request_start(method:, path:)
        @logger.send(@level, "AnthropicTools Request Started: #{method.to_s.upcase} #{path}")
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
