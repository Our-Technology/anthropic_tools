#!/usr/bin/env ruby
require 'bundler/setup'
require 'anthropic_tools'
require 'dotenv/load' # Load environment variables from .env file

# Configure the client
AnthropicTools.configure do |config|
  config.api_key = ENV['ANTHROPIC_API_KEY']
end

# Example of file processing
def file_processing_example
  puts "Starting file processing example with Claude..."
  
  # Check if a file path was provided
  if ARGV.empty?
    puts "Please provide a file path as an argument"
    puts "Example: ruby file_processing.rb /path/to/file.txt"
    exit 1
  end
  
  file_path = ARGV[0]
  
  # Create a file processing tool
  file_processor = AnthropicTools::Tool.new(
    name: 'process_file',
    description: 'Process the contents of a file',
    parameters: {
      type: 'object',
      properties: {
        action: {
          type: 'string',
          description: 'Action to perform on the file',
          enum: ['summarize', 'analyze', 'extract_info']
        }
      },
      required: ['action']
    }
  ) do |params|
    action = params['action']
    puts "Tool called with action: #{action}"
    
    begin
      # Process the file
      content = AnthropicTools::FileHelper.process_file(file_path)
      
      # Return content for Claude to work with
      {
        action: action,
        file_path: file_path,
        file_type: File.extname(file_path),
        content: content
      }
    rescue => e
      { error: "Failed to process file: #{e.message}" }
    end
  end
  
  # Create a conversation
  client = AnthropicTools.client
  conversation = client.create_conversation(
    system: "You are a helpful assistant that can analyze files. When asked to review a file, use the process_file tool."
  )
  
  # Add the file processor tool to the conversation
  conversation.add_tools(file_processor)
  
  # Ask Claude to analyze the file
  puts "Asking Claude to analyze the file: #{file_path}"
  response = conversation.send("Please analyze this file and tell me what it contains.")
  
  puts "Claude: #{response[:content]}"
end

# Run the example
file_processing_example
