module AnthropicTools
  # Middleware system for processing requests and responses
  #
  # The Middleware module provides a way to intercept and modify requests and responses
  # in the AnthropicTools client. This allows for adding custom functionality such as
  # logging, metrics collection, request/response transformation, and more.
  #
  # @example Adding middleware to the client
  #   AnthropicTools.configure do |config|
  #     # Add logging middleware
  #     config.add_middleware(AnthropicTools::Middleware::Logging.new(
  #       logger: Rails.logger,
  #       level: :info
  #     ))
  #   end
  #
  # @example Creating custom middleware
  #   class MyMiddleware < AnthropicTools::Middleware::Base
  #     def before_request(request)
  #       # Modify the request
  #       request[:headers]['X-Custom-Header'] = 'value'
  #       request
  #     end
  #
  #     def after_response(response)
  #       # Modify the response
  #       response[:custom_data] = 'value'
  #       response
  #     end
  #   end
  #
  #   AnthropicTools.configure do |config|
  #     config.add_middleware(MyMiddleware.new)
  #   end
  module Middleware
    # This module serves as a namespace for middleware components.
    # The actual middleware classes are defined in the middleware/ directory.
  end
end

# Require all middleware components
require_relative 'middleware/base'
require_relative 'middleware/stack'
require_relative 'middleware/logging'
require_relative 'middleware/metrics'
