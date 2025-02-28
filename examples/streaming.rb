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
  message = AnthropicTools::Message.new(
    role: 'user',
    content: 'Write a short poem about Ruby programming.'
  )
  
  puts "Claude: "
  
  # The block will be called for each chunk of the streaming response
  client.chat(message, stream: true) do |chunk|
    # Handle different types of chunks
    case chunk['type']
    when 'content_block_delta'
      # Print text deltas as they arrive
      if chunk['delta']['type'] == 'text'
        print chunk['delta']['text']
        $stdout.flush  # Ensure text is displayed immediately
      end
    when 'content_block_start'
      # Handle the start of a content block (e.g., tool_use)
      if chunk['content_block']['type'] == 'tool_use'
        puts "\n[Tool Use Requested: #{chunk['content_block']['tool_use']['name']}]"
      end
    when 'message_delta'
      # Check if the message is complete
      if chunk['delta']['stop_reason'] == 'end_turn'
        puts "\n\nMessage complete."
      end
    end
  end
end

# Streaming example with tool use
def streaming_tool_example
  puts "Starting streaming chat with Claude using tools..."
  
  client = AnthropicTools.client
  
  # Define a simple weather tool
  weather_tool = AnthropicTools::Tool.new(
    name: 'get_weather',
    description: 'Get weather information for a specific location. This tool returns the current weather conditions including temperature and general conditions like sunny, cloudy, or rainy.',
    input_schema: {
      type: 'object',
      properties: {
        location: { 
          type: 'string',
          description: 'The city and state, e.g. San Francisco, CA'
        }
      },
      required: ['location']
    }
  ) do |params|
    # This would normally call a weather API
    location = params['location']
    puts "Getting weather for #{location}..."
    { temperature: 22, conditions: 'Sunny' }
  end
  
  # Create a conversation with the tool
  conversation = AnthropicTools::Conversation.new(client, tools: [weather_tool])
  
  # Send a message that will likely trigger tool use
  puts "User: What's the weather like in Chicago?"
  response = conversation.send("What's the weather like in Chicago?")
  
  puts "Claude: #{response[:content]}"
end

# Run the examples
streaming_example
# Uncomment to run the tool example
# streaming_tool_example
