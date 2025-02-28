# Configure AnthropicTools
AnthropicTools.configure do |config|
  # Your Anthropic API key
  config.api_key = ENV['ANTHROPIC_API_KEY']
  
  # Model to use (default: claude-3-7-sonnet-20250219)
  config.model = ENV['ANTHROPIC_MODEL'] || 'claude-3-7-sonnet-20250219'
  
  # Maximum tokens to generate (default: 4096)
  config.max_tokens = ENV['ANTHROPIC_MAX_TOKENS']&.to_i || 4096
  
  # Temperature (default: 0.7)
  config.temperature = ENV['ANTHROPIC_TEMPERATURE']&.to_f || 0.7
  
  # Request timeout in seconds (default: 120)
  config.timeout = ENV['ANTHROPIC_TIMEOUT']&.to_i || 120
end
