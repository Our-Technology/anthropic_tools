module AnthropicTools
  # Base error class
  class Error < StandardError; end
  
  # Configuration errors
  class ConfigurationError < Error; end
  
  # Base API error class with response information
  class ApiError < Error
    attr_reader :status_code, :response, :request_id
    
    def initialize(message = nil, status_code = nil, response = nil, request_id = nil)
      @status_code = status_code
      @response = response
      @request_id = request_id
      
      error_message = message || "API error occurred"
      if request_id
        error_message += " (Request ID: #{request_id})"
      end
      
      super(error_message)
    end
  end
  
  # HTTP connection errors
  class APIConnectionError < ApiError; end
  class APIConnectionTimeoutError < APIConnectionError; end
  
  # Authentication errors
  class AuthenticationError < ApiError; end
  class PermissionDeniedError < ApiError; end
  
  # Request errors
  class BadRequestError < ApiError; end
  class NotFoundError < ApiError; end
  class UnprocessableEntityError < ApiError; end
  class RateLimitError < ApiError; end
  
  # Server errors
  class ServerError < ApiError; end
  class InternalServerError < ServerError; end
  class ServiceUnavailableError < ServerError; end
end
