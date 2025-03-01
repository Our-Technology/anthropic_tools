module AnthropicTools
  module Middleware
    # @abstract Base class for all middleware in the AnthropicTools gem
    #
    # The Base class provides the foundation for all middleware implementations.
    # Each middleware should inherit from this class and implement the
    # {#before_request} and {#after_response} methods to modify requests and responses.
    #
    # @example Creating a custom middleware
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
    class Base
      # Process a request before it is sent to the API
      #
      # @param request [Hash] The request object containing :method, :url, :headers, and :body
      # @return [Hash] The modified request object
      # @note This method must return the request object, even if unmodified
      def before_request(request)
        # Default implementation: no-op
        request
      end

      # Process a response after it is received from the API
      #
      # @param response [Hash] The response object containing :status, :headers, :body, and other metadata
      # @return [Hash] The modified response object
      # @note This method must return the response object, even if unmodified
      def after_response(response)
        # Default implementation: no-op
        response
      end
    end
  end
end
