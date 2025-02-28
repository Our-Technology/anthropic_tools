#!/usr/bin/env ruby
# Example demonstrating the new high-priority features:
# - Token counting
# - Improved streaming with event handlers
# - Error handling with request IDs
# - Timeout and retry configuration

require 'bundler/setup'
require 'anthropic_tools'

# Check for API key
if ENV['ANTHROPIC_API_KEY'].nil?
  puts "Error: ANTHROPIC_API_KEY environment variable is not set."
  puts "Please set it before running this example:"
  puts "  export ANTHROPIC_API_KEY=your_api_key_here"
  exit 1
end

# Configure AnthropicTools
AnthropicTools.configure do |config|
  config.api_key = ENV['ANTHROPIC_API_KEY']
  config.model = 'claude-3-opus-20240229'
  config.max_tokens = 1024
  config.temperature = 0.7
  
  # Configure timeout and retry settings
  config.timeout = 60 # 60 seconds timeout
  config.max_retries = 3 # Retry up to 3 times
  config.retry_initial_delay = 1.0 # Start with 1 second delay
end

client = AnthropicTools.client

puts "=== Token Counting Example ==="
begin
  # Count tokens for a message
  message = "Hello, I'm testing the token counting feature of AnthropicTools."
  messages = [{ role: 'user', content: message }]
  
  # Count tokens without sending a message
  token_count = client.count_tokens(messages)
  puts "Message: #{message}"
  puts "Token count: #{token_count[:input_tokens]} tokens"
  puts "Request ID: #{token_count[:_request_id]}" if token_count[:_request_id]
  puts
rescue AnthropicTools::ApiError => e
  puts "Error counting tokens: #{e.message}"
  puts "Status code: #{e.status_code}" if e.respond_to?(:status_code)
  puts "Request ID: #{e.request_id}" if e.respond_to?(:request_id)
end

puts "=== Chat Example ==="
begin
  # Basic chat example
  response = client.chat(
    [{ role: 'user', content: 'Write a haiku about Ruby programming.' }],
    max_tokens: 300
  )
  
  puts "Response content: #{response[:content]}"
  puts "Usage: #{response[:usage].inspect}" if response[:usage]
  puts "Request ID: #{response[:_request_id]}" if response[:_request_id]
  puts
rescue AnthropicTools::ApiError => e
  puts "Error in chat: #{e.message}"
  puts "Status code: #{e.status_code}" if e.respond_to?(:status_code)
  puts "Request ID: #{e.request_id}" if e.respond_to?(:request_id)
end

puts "=== Error Handling Example ==="
begin
  # Deliberately cause an error by using an invalid model
  invalid_client = AnthropicTools::Client.new(
    AnthropicTools::Configuration.new.tap { |c| 
      c.api_key = ENV['ANTHROPIC_API_KEY']
      c.model = 'invalid-model-name'
    }
  )
  
  response = invalid_client.chat(
    [{ role: 'user', content: 'This should fail' }]
  )
rescue AnthropicTools::BadRequestError => e
  puts "Bad Request Error: #{e.message}"
  puts "Status code: #{e.status_code}" if e.respond_to?(:status_code)
  puts "Request ID: #{e.request_id}" if e.respond_to?(:request_id)
rescue AnthropicTools::ApiError => e
  puts "API Error: #{e.message}"
  puts "Status code: #{e.status_code}" if e.respond_to?(:status_code)
  puts "Request ID: #{e.request_id}" if e.respond_to?(:request_id)
end

puts "\n=== Dynamic Timeout Example ==="
begin
  # Use dynamic timeout calculation for a large request
  puts "Sending request with large max_tokens value..."
  
  # This would normally use a dynamically calculated timeout
  # based on the max_tokens value
  response = client.chat(
    [{ role: 'user', content: 'Write a one-paragraph summary of Ruby on Rails.' }],
    max_tokens: 4000 # Large token count to demonstrate dynamic timeout, but within limits
  )
  
  puts "Response received successfully!"
  puts "Content length: #{response[:content].length} characters"
  puts "Token usage: #{response[:usage].inspect}" if response[:usage]
  puts "Request ID: #{response[:_request_id]}" if response[:_request_id]
rescue AnthropicTools::APIConnectionTimeoutError => e
  puts "Timeout Error: #{e.message}"
  puts "Request ID: #{e.request_id}" if e.respond_to?(:request_id)
rescue AnthropicTools::ApiError => e
  puts "API Error: #{e.message}"
  puts "Status code: #{e.status_code}" if e.respond_to?(:status_code)
  puts "Request ID: #{e.request_id}" if e.respond_to?(:request_id)
end

puts "\nAll examples completed!"
