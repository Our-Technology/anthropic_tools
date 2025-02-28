#!/usr/bin/env ruby
require 'bundler/setup'
require 'anthropic_tools'

begin
  require 'dotenv/load' # Load environment variables from .env file
rescue LoadError
  # dotenv is optional - continue without it if not available
  puts "Note: dotenv gem not found. Using environment variables directly."
end

# Configure the client
AnthropicTools.configure do |config|
  config.api_key = ENV['ANTHROPIC_API_KEY']
end

# Example with tool usage
def tool_usage_example
  puts "Starting tool usage example with Claude..."
  
  # Define a weather tool
  weather_tool = AnthropicTools::Tool.new(
    name: 'get_weather',
    description: 'Get weather information for a location',
    parameters: {
      type: 'object',
      properties: {
        location: {
          type: 'string',
          description: 'City name or location'
        }
      },
      required: ['location']
    }
  ) do |params|
    # This would normally call a weather API
    puts "Tool called with location: #{params['location']}"
    
    # Return mock weather data
    {
      location: params['location'],
      temperature: 22,
      conditions: 'Sunny',
      humidity: 45,
      wind_speed: 10
    }
  end
  
  # Define a calculator tool
  calculator_tool = AnthropicTools::Tool.new(
    name: 'calculate',
    description: 'Perform a calculation',
    parameters: {
      type: 'object',
      properties: {
        expression: {
          type: 'string',
          description: 'Mathematical expression to evaluate'
        }
      },
      required: ['expression']
    }
  ) do |params|
    expression = params['expression']
    puts "Tool called with expression: #{expression}"
    
    begin
      # Very simple evaluator for demo purposes only
      # In production, you would use a safer evaluation method
      result = eval(expression)
      { result: result }
    rescue => e
      { error: "Could not evaluate expression: #{e.message}" }
    end
  end
  
  # Create a conversation
  client = AnthropicTools.client
  conversation = client.create_conversation(
    system: "You are a helpful assistant with access to tools. Always use tools when appropriate."
  )
  
  # Add tools to the conversation
  conversation.add_tools(weather_tool, calculator_tool)
  
  # Interaction loop
  puts "Type 'exit' to quit"
  puts "Ask Claude something (try asking about weather or calculations):"
  
  loop do
    print "> "
    user_input = gets.chomp
    break if user_input.downcase == 'exit'
    
    puts "Sending message to Claude..."
    response = conversation.send(user_input)
    
    puts "Claude: #{response[:content]}"
    puts
  end
end

# Run the example
tool_usage_example
