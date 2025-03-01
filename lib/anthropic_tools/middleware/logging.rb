require 'logger'
require 'json'
require_relative 'base'

module AnthropicTools
  module Middleware
    # Middleware for logging requests and responses
    #
    # The Logging middleware logs information about requests and responses,
    # including method, URL, status code, and optionally the request and response bodies.
    # It can be configured to redact sensitive information like API keys.
    #
    # @example Basic usage
    #   AnthropicTools.configure do |config|
    #     config.add_middleware(AnthropicTools::Middleware::Logging.new(
    #       logger: Rails.logger,
    #       level: :info
    #     ))
    #   end
    #
    # @example With custom configuration
    #   AnthropicTools.configure do |config|
    #     config.add_middleware(AnthropicTools::Middleware::Logging.new(
    #       logger: Rails.logger,
    #       level: :debug,
    #       log_request_body: true,
    #       log_response_body: true,
    #       redact_api_key: true
    #     ))
    #   end
    class Logging < Base
      # Create a new logging middleware
      #
      # @param logger [Logger] The logger to use (defaults to a new Logger instance)
      # @param level [Symbol, String] The log level to use (:debug, :info, :warn, :error, :fatal)
      # @param log_request_body [Boolean] Whether to log the request body
      # @param log_response_body [Boolean] Whether to log the response body
      # @param redact_api_key [Boolean] Whether to redact API keys from logs
      # @param redact_patterns [Array<Regexp>] Additional patterns to redact from logs
      # @return [Logging] A new logging middleware instance
      def initialize(logger: nil, level: :info, log_request_body: false, log_response_body: false, redact_api_key: true, redact_patterns: [])
        @logger = logger || Logger.new(STDOUT)
        @level = level.to_sym
        @log_request_body = log_request_body
        @log_response_body = log_response_body
        @redact_api_key = redact_api_key
        @redact_patterns = redact_patterns
      end

      # Process a request before it is sent to the API
      #
      # Logs information about the request, including method, URL, and optionally the request body.
      # Sensitive information like API keys can be redacted from the logs.
      #
      # @param request [Hash] The request object containing :method, :url, :headers, and :body
      # @return [Hash] The request object (unmodified)
      def before_request(request)
        @logger.send(@level, "AnthropicTools Request: #{request[:method].upcase} #{request[:url]}")
        
        if @log_request_body && request[:body]
          # Redact sensitive information
          body = JSON.parse(request[:body])
          body = redact_sensitive_data(body)
          @logger.send(@level, "Request Body: #{body.to_json}")
        end

        # Store start time for duration calculation
        request[:_start_time] = Time.now
        request
      end

      # Process a response after it is received from the API
      #
      # Logs information about the response, including status code and optionally the response body.
      # Sensitive information like API keys can be redacted from the logs.
      #
      # @param response [Hash] The response object containing :status, :headers, :body, and other metadata
      # @return [Hash] The response object (unmodified)
      def after_response(response)
        duration = Time.now - response[:_request][:_start_time]
        @logger.send(@level, "AnthropicTools Response: Status #{response[:status]} (#{duration.round(2)}s)")
        
        if @log_response_body && response[:body]
          # Redact sensitive information
          body = JSON.parse(response[:body])
          body = redact_sensitive_data(body)
          @logger.send(@level, "Response Body: #{body.to_json}")
        end

        response
      end

      private

      # Redact sensitive information from a hash
      #
      # @param data [Hash] The data to redact
      # @return [Hash] The redacted data
      def redact_sensitive_data(data)
        return data unless data.is_a?(Hash)

        data = data.dup
        # Redact API keys
        if data['api_key']
          data['api_key'] = '[REDACTED]'
        end

        # Recursively redact nested hashes
        data.each do |key, value|
          if value.is_a?(Hash)
            data[key] = redact_sensitive_data(value)
          elsif value.is_a?(Array)
            data[key] = value.map { |v| v.is_a?(Hash) ? redact_sensitive_data(v) : v }
          end
        end

        data
      end
    end
  end
end
