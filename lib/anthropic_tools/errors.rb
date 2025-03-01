module AnthropicTools
  # Base error class for all AnthropicTools errors
  #
  # All errors raised by the AnthropicTools gem inherit from this class,
  # allowing users to rescue all AnthropicTools errors with a single rescue.
  #
  # @example Rescuing all AnthropicTools errors
  #   begin
  #     client.chat(messages: [{ role: 'user', content: 'Hello' }])
  #   rescue AnthropicTools::Error => e
  #     puts "AnthropicTools error: #{e.message}"
  #   end
  class Error < StandardError; end
  
  # Error raised when the configuration is invalid
  #
  # This error is raised when the configuration is missing required values
  # or contains invalid values.
  #
  # @example
  #   begin
  #     AnthropicTools::Client.new(config: AnthropicTools::Configuration.new)
  #   rescue AnthropicTools::ConfigurationError => e
  #     puts "Configuration error: #{e.message}"
  #   end
  class ConfigurationError < Error; end
  
  # Base API error class with response information
  #
  # This error is raised when the API returns an error response.
  # It contains information about the error, including the status code,
  # error type, and error message.
  #
  # @example Handling API errors
  #   begin
  #     client.chat(messages: [{ role: 'user', content: 'Hello' }])
  #   rescue AnthropicTools::ApiError => e
  #     puts "API error: #{e.message} (#{e.status_code})"
  #     puts "Error type: #{e.error_type}"
  #     puts "Error message: #{e.error_message}"
  #   end
  class ApiError < Error
    # @return [Integer] The HTTP status code
    # @return [String] The error type
    # @return [String] The error message
    # @return [Hash] The full error response
    # @return [String] The request ID
    attr_reader :status_code, :error_type, :error_message, :response, :request_id
    
    # Create a new API error
    #
    # @param message [String] The error message
    # @param status_code [Integer] The HTTP status code
    # @param error_type [String] The error type
    # @param error_message [String] The error message
    # @param response [Hash] The full error response
    # @param request_id [String] The request ID
    # @return [ApiError] A new API error instance
    def initialize(message, status_code: nil, error_type: nil, error_message: nil, response: nil, request_id: nil)
      @status_code = status_code
      @error_type = error_type
      @error_message = error_message
      @response = response
      @request_id = request_id
      super(message)
    end
  end
  
  # HTTP connection errors
  #
  # This error is raised when there is a problem with the HTTP connection.
  class APIConnectionError < ApiError; end
  
  # Error raised when the API request times out
  #
  # This error is raised when the API request takes longer than the configured timeout.
  #
  # @example Handling timeout errors
  #   begin
  #     client.chat(messages: [{ role: 'user', content: 'Hello' }])
  #   rescue AnthropicTools::APIConnectionTimeoutError => e
  #     puts "Timeout error: #{e.message}"
  #   end
  class APIConnectionTimeoutError < APIConnectionError; end
  
  # Authentication errors
  #
  # This error is raised when there is a problem with authentication.
  class AuthenticationError < ApiError; end
  
  # Error raised when the API request is unauthorized
  #
  # This error is raised when the API key is invalid or missing.
  #
  # @example Handling unauthorized errors
  #   begin
  #     client.chat(messages: [{ role: 'user', content: 'Hello' }])
  #   rescue AnthropicTools::PermissionDeniedError => e
  #     puts "Unauthorized error: #{e.message}"
  #   end
  class PermissionDeniedError < ApiError; end
  
  # Request errors
  #
  # This error is raised when there is a problem with the request.
  class BadRequestError < ApiError; end
  
  # Error raised when the requested resource is not found
  #
  # This error is raised when the requested resource does not exist.
  #
  # @example Handling not found errors
  #   begin
  #     client.chat(messages: [{ role: 'user', content: 'Hello' }])
  #   rescue AnthropicTools::NotFoundError => e
  #     puts "Not found error: #{e.message}"
  #   end
  class NotFoundError < ApiError; end
  
  # Error raised when the request is unprocessable
  #
  # This error is raised when the request is invalid or cannot be processed.
  #
  # @example Handling unprocessable entity errors
  #   begin
  #     client.chat(messages: [{ role: 'user', content: 'Hello' }])
  #   rescue AnthropicTools::UnprocessableEntityError => e
  #     puts "Unprocessable entity error: #{e.message}"
  #   end
  class UnprocessableEntityError < ApiError; end
  
  # Error raised when the API rate limit is exceeded
  #
  # This error is raised when the API rate limit is exceeded.
  #
  # @example Handling rate limit errors
  #   begin
  #     client.chat(messages: [{ role: 'user', content: 'Hello' }])
  #   rescue AnthropicTools::RateLimitError => e
  #     puts "Rate limit error: #{e.message}"
  #   end
  class RateLimitError < ApiError; end
  
  # Server errors
  #
  # This error is raised when there is a problem with the server.
  class ServerError < ApiError; end
  
  # Error raised when there is an internal server error
  #
  # This error is raised when there is an internal server error.
  #
  # @example Handling internal server errors
  #   begin
  #     client.chat(messages: [{ role: 'user', content: 'Hello' }])
  #   rescue AnthropicTools::InternalServerError => e
  #     puts "Internal server error: #{e.message}"
  #   end
  class InternalServerError < ServerError; end
  
  # Error raised when the service is unavailable
  #
  # This error is raised when the service is temporarily unavailable.
  #
  # @example Handling service unavailable errors
  #   begin
  #     client.chat(messages: [{ role: 'user', content: 'Hello' }])
  #   rescue AnthropicTools::ServiceUnavailableError => e
  #     puts "Service unavailable error: #{e.message}"
  #   end
  class ServiceUnavailableError < ServerError; end
end
