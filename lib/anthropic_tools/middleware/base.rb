module AnthropicTools
  module Middleware
    # Base class for middleware
    class Base
      # Called before a request is sent
      # @param request [Hash] The request to process
      # @return [Hash] The processed request
      def before_request(request)
        # Default implementation: no-op
        request
      end

      # Called after a response is received
      # @param response [Hash] The response to process
      # @return [Hash] The processed response
      def after_response(response)
        # Default implementation: no-op
        response
      end
    end
  end
end
