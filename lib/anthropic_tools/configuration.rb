module AnthropicTools
  class Configuration
    attr_accessor :api_key, :api_url, :api_version, :model, :max_tokens, :temperature, 
                  :timeout, :max_retries, :retry_initial_delay, :retry_max_delay, 
                  :retry_jitter, :retry_statuses

    def initialize
      @api_key = nil
      @api_url = 'https://api.anthropic.com'
      @api_version = '2023-06-01'
      @model = 'claude-3-7-sonnet-20250219'
      @max_tokens = 4096
      @temperature = 0.7
      @timeout = 120
      @max_retries = 2
      @retry_initial_delay = 0.5
      @retry_max_delay = 8.0
      @retry_jitter = 0.25
      @retry_statuses = [408, 429, 500, 502, 503, 504]
    end
    
    # Calculate dynamic timeout based on max_tokens
    # For large token requests, we need longer timeouts
    def calculate_timeout(max_tokens = nil)
      tokens = max_tokens || @max_tokens
      
      # Base timeout is 10 minutes (600 seconds)
      minimum_timeout = 600
      
      # Calculate timeout based on tokens (similar to TypeScript SDK formula)
      # 60 minutes * tokens / 128,000
      calculated_timeout = (60 * 60 * tokens) / 128_000.0
      
      # Use the larger of minimum or calculated timeout
      calculated_timeout < minimum_timeout ? minimum_timeout : calculated_timeout
    end
  end
end
