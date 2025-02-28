#!/usr/bin/env ruby
require 'bundler/setup'
require 'anthropic_tools'
require 'dotenv/load' # Load environment variables from .env file

# Configure the client
AnthropicTools.configure do |config|
  config.api_key = ENV['ANTHROPIC_API_KEY']
end

# Streaming example
def streaming_example
  puts "Starting streaming chat with Claude..."
  
  client = AnthropicTools.client
  
  # Send a message with streaming enabled
  message = { role: 'user', content: 'Write a short poem about Ruby programming.' }
  
  puts "Claude: "
  
  # The block will be called for each chunk of the streaming response
  client.chat(message, stream: true) do |chunk|
    # Handle different types of chunks
    case chunk['type']
    when 'content_block_delta'
      # Print text deltas as they arrive
      print chunk['delta']['text']
      $stdout.flush  # Ensure text is displayed immediately
    when 'message_delta'
      # Check if the message is complete
      if chunk['delta']['stop_reason'] == 'end_turn'
        puts "\n\nMessage complete."
      end
    end
  end
end

# Run the example
streaming_example
