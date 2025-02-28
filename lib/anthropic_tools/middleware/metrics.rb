require 'json'
require_relative 'base'

module AnthropicTools
  module Middleware
    # Metrics middleware for collecting metrics
    class Metrics < Base
      # Initialize the metrics middleware
      # @param collector [Object] The metrics collector to use
      def initialize(collector)
        @collector = collector
      end

      # Record the start of a request
      # @param request [Hash] The request to process
      # @return [Hash] The request (unmodified)
      def before_request(request)
        request[:_start_time] = Time.now
        request
      end

      # Record metrics for the response
      # @param response [Hash] The response to process
      # @return [Hash] The processed response
      def after_response(response)
        duration = Time.now - response[:_request][:_start_time]
        
        # Record metrics
        @collector.record_request(
          method: response[:_request][:method],
          path: response[:_request][:url],
          status: response[:status],
          duration: duration
        )

        # Record token usage if available
        if response[:body] && (body = JSON.parse(response[:body]) rescue nil)
          if body['usage']
            @collector.record_token_usage(
              input_tokens: body['usage']['input_tokens'],
              output_tokens: body['usage']['output_tokens']
            )
          end
        end

        response
      end
    end
  end
end
