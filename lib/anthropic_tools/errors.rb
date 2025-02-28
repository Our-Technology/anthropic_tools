module AnthropicTools
  class Error < StandardError; end
  class ConfigurationError < Error; end
  class ApiError < Error; end
  class AuthenticationError < ApiError; end
  class BadRequestError < ApiError; end
  class RateLimitError < ApiError; end
  class ServerError < ApiError; end
end
