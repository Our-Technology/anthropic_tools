module AnthropicTools
  module Middleware
    # Manages a stack of middleware for processing requests and responses
    #
    # The Stack class maintains an ordered collection of middleware and provides
    # methods to process requests and responses through the middleware chain.
    # Requests flow through middleware in the order they're added, while
    # responses flow through middleware in reverse order.
    #
    # @example Using the middleware stack
    #   stack = AnthropicTools::Middleware::Stack.new
    #   stack.add(LoggingMiddleware.new)
    #   stack.add(MetricsMiddleware.new)
    #   
    #   # Process a request through the middleware stack
    #   processed_request = stack.process_request(request)
    #   
    #   # Process a response through the middleware stack (in reverse order)
    #   processed_response = stack.process_response(response)
    class Stack
      # Initialize a new middleware stack
      #
      # @return [Stack] A new middleware stack instance
      def initialize
        @middlewares = []
      end

      # Add a middleware to the stack
      #
      # @param middleware [Base] The middleware to add
      # @return [self] The middleware stack instance for method chaining
      # @raise [ArgumentError] If the middleware doesn't respond to required methods
      def add(middleware)
        unless middleware.respond_to?(:before_request) && middleware.respond_to?(:after_response)
          raise ArgumentError, "Middleware must implement before_request and after_response methods"
        end

        @middlewares << middleware
        self
      end

      # Process a request through all middleware in the stack
      #
      # Requests flow through middleware in the order they were added to the stack.
      # Each middleware's `before_request` method is called with the request object,
      # and the result is passed to the next middleware.
      #
      # @param request [Hash] The request to process
      # @return [Hash] The processed request
      def process_request(request)
        return request if @middlewares.empty?

        @middlewares.reduce(request) do |req, middleware|
          middleware.before_request(req)
        end
      end

      # Process a response through all middleware in the stack
      #
      # Responses flow through middleware in reverse order (compared to how they were added).
      # Each middleware's `after_response` method is called with the response object,
      # and the result is passed to the next middleware.
      #
      # @param response [Hash] The response to process
      # @return [Hash] The processed response
      def process_response(response)
        return response if @middlewares.empty?

        @middlewares.reverse.reduce(response) do |res, middleware|
          middleware.after_response(res)
        end
      end

      # Check if the middleware stack is empty
      #
      # @return [Boolean] true if the stack has no middleware, false otherwise
      def empty?
        @middlewares.empty?
      end

      # Get the number of middleware in the stack
      #
      # @return [Integer] The number of middleware in the stack
      def size
        @middlewares.size
      end
    end
  end
end
