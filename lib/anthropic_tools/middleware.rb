module AnthropicTools
  # The Middleware module provides a way to intercept and modify requests and responses
  # in the AnthropicTools client. Middleware can be used for logging, metrics collection,
  # request/response transformation, and other cross-cutting concerns.
  #
  # Each middleware must implement three methods:
  # - `initialize`: Takes any configuration options
  # - `before_request`: Called before a request is sent, can modify the request
  # - `after_response`: Called after a response is received, can modify the response
  #
  # @example Creating a simple logging middleware
  #   class LoggingMiddleware
  #     def initialize(logger: Logger.new(STDOUT))
  #       @logger = logger
  #     end
  #
  #     def before_request(request)
  #       @logger.info("Sending request to #{request[:url]}")
  #       request # Return the request (possibly modified)
  #     end
  #
  #     def after_response(response)
  #       @logger.info("Received response with status #{response[:status]}")
  #       response # Return the response (possibly modified)
  #     end
  #   end
  #
  #   AnthropicTools.configure do |config|
  #     config.add_middleware(LoggingMiddleware.new)
  #   end
  module Middleware
  end
end

# Require all middleware files
require_relative 'middleware/base'
require_relative 'middleware/stack'
require_relative 'middleware/logging'
require_relative 'middleware/metrics'
