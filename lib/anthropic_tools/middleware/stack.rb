module AnthropicTools
  module Middleware
    # Stack to manage middleware execution
    class Stack
      def initialize
        @middlewares = []
      end

      # Add a middleware to the stack
      # @param middleware [Object] The middleware to add
      def add(middleware)
        @middlewares << middleware
      end

      # Check if the stack is empty
      # @return [Boolean] True if the stack is empty
      def empty?
        @middlewares.empty?
      end

      # Process a request through all middlewares
      # @param request [Hash] The request to process
      # @return [Hash] The processed request
      def process_request(request)
        return request if empty?
        
        @middlewares.reduce(request) do |req, middleware|
          middleware.before_request(req)
        end
      end

      # Process a response through all middlewares in reverse order
      # @param response [Hash] The response to process
      # @return [Hash] The processed response
      def process_response(response)
        return response if empty?
        
        @middlewares.reverse.reduce(response) do |res, middleware|
          middleware.after_response(res)
        end
      end
    end
  end
end
