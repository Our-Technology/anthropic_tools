#!/usr/bin/env ruby
require 'bundler/setup'
require 'anthropic_tools'
require 'dotenv/load' # Load environment variables from .env file

# Configure the client
AnthropicTools.configure do |config|
  config.api_key = ENV['ANTHROPIC_API_KEY']
end

# Simple chat example
def basic_chat
  puts "Starting basic chat with Claude..."
  
  client = AnthropicTools.client
  
  # Send a simple message
  message = { role: 'user', content: 'Hello Claude! What can you do?' }
  
  response = client.chat(message)
  
  puts "Claude: #{response[:content]}"
end

# Run the example
basic_chat
