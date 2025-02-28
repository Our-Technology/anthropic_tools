require 'logger'
require 'json'
require_relative 'base'

module AnthropicTools
  module Middleware
    # Logging middleware for request/response logging
    class Logging < Base
      # Initialize the logging middleware
      # @param logger [Logger] The logger to use
      # @param level [Symbol] The log level to use
      # @param log_request_body [Boolean] Whether to log request bodies
      # @param log_response_body [Boolean] Whether to log response bodies
      def initialize(logger: Logger.new(STDOUT), level: :info, log_request_body: false, log_response_body: false)
        @logger = logger
        @level = level
        @log_request_body = log_request_body
        @log_response_body = log_response_body
      end

      # Log the request
      # @param request [Hash] The request to log
      # @return [Hash] The request (unmodified)
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

      # Log the response
      # @param response [Hash] The response to log
      # @return [Hash] The response (unmodified)
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
