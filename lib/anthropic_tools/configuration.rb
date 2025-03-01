module AnthropicTools
  # Configuration for the AnthropicTools client
  #
  # The Configuration class holds all the settings for the AnthropicTools client,
  # including API credentials, model settings, timeout and retry settings,
  # middleware configuration, and instrumentation settings.
  #
  # @example Basic configuration
  #   AnthropicTools.configure do |config|
  #     config.api_key = ENV['ANTHROPIC_API_KEY']
  #     config.model = 'claude-3-opus-20240229'
  #     config.max_tokens = 4096
  #     config.temperature = 0.7
  #   end
  #
  # @example Advanced configuration
  #   AnthropicTools.configure do |config|
  #     # API settings
  #     config.api_key = ENV['ANTHROPIC_API_KEY']
  #     config.api_url = 'https://api.anthropic.com'
  #     config.api_version = '2023-06-01'
  #     
  #     # Model settings
  #     config.model = 'claude-3-opus-20240229'
  #     config.max_tokens = 4096
  #     config.temperature = 0.7
  #     
  #     # Timeout and retry settings
  #     config.timeout = 60
  #     config.max_retries = 3
  #     config.retry_initial_delay = 1.0
  #     config.retry_max_delay = 8.0
  #     config.retry_jitter = 0.25
  #     config.retry_statuses = [408, 429, 500, 502, 503, 504]
  #     
  #     # Middleware
  #     config.add_middleware(AnthropicTools::Middleware::Logging.new(
  #       logger: Rails.logger,
  #       level: :info
  #     ))
  #     
  #     # Instrumentation
  #     config.metrics_collector = AnthropicTools::Instrumentation::LoggerMetricsCollector.new(
  #       logger: Rails.logger
  #     )
  #   end
  class Configuration
    # @return [String] The Anthropic API key
    # @return [String] The Anthropic API URL
    # @return [String] The Anthropic API version
    # @return [String] The Claude model to use
    # @return [Integer] The maximum number of tokens to generate
    # @return [Float] The temperature for generation (0.0 to 1.0)
    # @return [Integer] The timeout in seconds for API requests
    # @return [Integer] The maximum number of retry attempts
    # @return [Float] The initial delay in seconds between retries
    # @return [Float] The maximum delay in seconds between retries
    # @return [Float] The jitter factor for retry delay randomization
    # @return [Array<Integer>] The HTTP status codes to retry
    # @return [Logger] The logger instance
    # @return [Boolean] Whether debug mode is enabled
    # @return [Instrumentation::MetricsCollector] The metrics collector
    attr_accessor :api_key, :api_url, :api_version, :model, :max_tokens, :temperature, 
                  :timeout, :max_retries, :retry_initial_delay, :retry_max_delay, 
                  :retry_jitter, :retry_statuses, :logger, :debug, :metrics_collector

    # Initialize a new configuration with default values
    #
    # @return [Configuration] A new configuration instance with default values
    def initialize
      @api_key = nil
      @api_url = 'https://api.anthropic.com'
      @api_version = '2023-06-01'
      @model = 'claude-3-7-sonnet-20250219'
      @max_tokens = 4096
      @temperature = 0.7
      @timeout = 120
      @max_retries = 2
      @retry_initial_delay = 0.5
      @retry_max_delay = 8.0
      @retry_jitter = 0.25
      @retry_statuses = [408, 429, 500, 502, 503, 504]
      @logger = Logger.new(STDOUT)
      @debug = false
      @metrics_collector = nil
      @middleware_stack = Middleware::Stack.new
    end
    
    # Calculate dynamic timeout based on max_tokens
    #
    # For large token requests, we need longer timeouts to account for
    # the increased generation time. This method calculates an appropriate
    # timeout based on the number of tokens requested.
    #
    # @param max_tokens [Integer, nil] The maximum number of tokens to generate, or nil to use the configured value
    # @return [Integer] The calculated timeout in seconds
    def calculate_timeout(max_tokens = nil)
      tokens = max_tokens || @max_tokens
      
      # Base timeout is 10 minutes (600 seconds)
      minimum_timeout = 600
      
      # Calculate timeout based on tokens (similar to TypeScript SDK formula)
      # 60 minutes * tokens / 128,000
      calculated_timeout = (60 * 60 * tokens) / 128_000.0
      
      # Use the larger of minimum or calculated timeout
      calculated_timeout < minimum_timeout ? minimum_timeout : calculated_timeout
    end

    # Add middleware to the stack
    #
    # @param middleware [Middleware::Base] The middleware to add
    # @return [self] The configuration object for method chaining
    def add_middleware(middleware)
      @middleware_stack.add(middleware)
      self
    end

    # Get the middleware stack
    #
    # @return [Middleware::Stack] The middleware stack
    def middleware_stack
      @middleware_stack
    end

    # Set the metrics collector
    #
    # If debug mode is enabled and no metrics collector is provided,
    # a logging middleware will be added to the stack.
    #
    # @param collector [Instrumentation::MetricsCollector] The metrics collector to use
    # @return [self] The configuration object for method chaining
    def metrics_collector=(collector)
      @metrics_collector = collector
      
      # If debug mode is enabled and we're using a logger-based collector,
      # add a logging middleware
      if @debug && @metrics_collector.nil?
        add_middleware(Middleware::Logging.new(logger: @logger))
      end
      
      self
    end

    # Get the metrics collector, creating a default one if none exists
    #
    # @return [Instrumentation::MetricsCollector] The metrics collector
    def metrics_collector
      @metrics_collector ||= if @debug
                               Instrumentation::LoggerMetricsCollector.new(logger: @logger)
                             else
                               Instrumentation::NullMetricsCollector.new
                             end
    end

    # Set debug mode
    #
    # If debug mode is enabled, a logging middleware will be added to the stack.
    #
    # @param value [Boolean] Whether to enable debug mode
    # @return [self] The configuration object for method chaining
    def debug=(value)
      @debug = value
      
      # If debug mode is enabled, add a logging middleware
      if @debug && !middleware_stack.empty?
        add_middleware(Middleware::Logging.new(logger: @logger))
      end
      
      self
    end
  end
end
