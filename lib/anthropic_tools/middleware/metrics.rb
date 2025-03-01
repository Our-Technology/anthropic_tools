require 'json'
require_relative 'base'

module AnthropicTools
  module Middleware
    # Middleware for collecting metrics on API usage
    #
    # The Metrics middleware collects information about API requests, responses,
    # and token usage. It uses a metrics collector to record this information,
    # which can be used for monitoring, debugging, and optimization.
    #
    # @example Basic usage
    #   AnthropicTools.configure do |config|
    #     config.add_middleware(AnthropicTools::Middleware::Metrics.new(
    #       collector: AnthropicTools::Instrumentation::LoggerMetricsCollector.new(
    #         logger: Rails.logger
    #       )
    #     ))
    #   end
    class Metrics < Base
      # Create a new metrics middleware
      #
      # @param collector [Instrumentation::MetricsCollector] The metrics collector to use
      # @return [Metrics] A new metrics middleware instance
      def initialize(collector)
        @collector = collector
      end

      # Process a request before it is sent to the API
      #
      # Records the start time of the request for duration calculation.
      #
      # @param request [Hash] The request object containing :method, :url, :headers, and :body
      # @return [Hash] The request object with added metadata
      def before_request(request)
        # Add start time to the request for duration calculation
        request[:_start_time] = Time.now
        
        # Record the request start if the collector supports it
        if @collector.respond_to?(:record_request_start)
          @collector.record_request_start(
            method: request[:method],
            path: request[:url]
          )
        end
        
        request
      end

      # Process a response after it is received from the API
      #
      # Records metrics about the request, response, and token usage.
      #
      # @param response [Hash] The response object containing :status, :headers, :body, and other metadata
      # @return [Hash] The response object (unmodified)
      def after_response(response)
        # Calculate duration
        start_time = response[:_request][:_start_time]
        duration = Time.now - start_time if start_time
        
        # Record request metrics
        @collector.record_request(
          method: response[:_request][:method],
          path: response[:_request][:url],
          status: response[:status],
          duration: duration || 0
        )
        
        # Record token usage if available
        if response[:body] && response[:body].is_a?(String)
          begin
            body = JSON.parse(response[:body])
            if body['usage']
              @collector.record_token_usage(
                input_tokens: body['usage']['input_tokens'],
                output_tokens: body['usage']['output_tokens']
              )
            end
          rescue JSON::ParserError
            # Ignore parsing errors
          end
        end
        
        response
      end
    end
  end
end
