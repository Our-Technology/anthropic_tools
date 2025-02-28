module AnthropicTools
  class Configuration
    attr_accessor :api_key, :api_url, :api_version, :model, :max_tokens, :temperature, :timeout

    def initialize
      @api_key = nil
      @api_url = 'https://api.anthropic.com'
      @api_version = '2023-06-01'
      @model = 'claude-3-7-sonnet-20250219'
      @max_tokens = 4096
      @temperature = 0.7
      @timeout = 120
    end
  end
end
