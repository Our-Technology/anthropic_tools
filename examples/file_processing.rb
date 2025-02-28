#!/usr/bin/env ruby
# frozen_string_literal: true

require "anthropic_tools"

# Configure the AnthropicTools client
AnthropicTools.configure do |config|
  config.api_key = ENV["ANTHROPIC_API_KEY"] # Set your API key in environment variable
  config.model = "claude-3-7-sonnet-20250219" # Use the latest Claude model
  config.max_tokens = 4096
  config.temperature = 0.7
end

# Example file processing with Claude tools
class FileProcessor
  def initialize
    @client = AnthropicTools::Client.new
  end

  def analyze_file(file_path)
    file_content = File.read(file_path)
    file_type = File.extname(file_path).delete_prefix(".")
    
    # Define the tools available to Claude
    tools = [
      {
        name: "extract_data",
        description: "Extract structured data from text",
        input_schema: {
          type: "object",
          properties: {
            data_format: {
              type: "string",
              description: "Format of the data to extract (JSON, CSV, etc.)"
            },
            fields: {
              type: "array",
              items: { type: "string" },
              description: "List of fields to extract"
            }
          },
          required: ["data_format", "fields"]
        }
      }
    ]
    
    # Create a conversation with Claude
    conversation = AnthropicTools::Conversation.new(
      system: "You are a helpful assistant that specializes in analyzing files and extracting structured information.",
      tools: tools
    )
    
    # Add the file content to the conversation
    prompt = "Please analyze the following #{file_type} file and extract relevant information:\n\n#{file_content}"
    response = conversation.send_message(prompt)
    
    # Process and return the response
    response
  end
  
  # Ruby 3.1+ pattern matching example for processing different file types
  def determine_extraction_strategy(file_path)
    case File.extname(file_path)
    in ".csv"
      { strategy: :tabular, parser: :csv }
    in ".json"
      { strategy: :structured, parser: :json }
    in ".txt"
      { strategy: :text, parser: :plain }
    in ".md"
      { strategy: :text, parser: :markdown }
    in ".xml" | ".html"
      { strategy: :structured, parser: :xml }
    else
      { strategy: :unknown, parser: nil }
    end
  end
end

# Usage example
if __FILE__ == $PROGRAM_NAME
  if ARGV.empty?
    puts "Usage: ruby file_processing.rb <file_path>"
    exit 1
  end
  
  file_path = ARGV[0]
  unless File.exist?(file_path)
    puts "Error: File '#{file_path}' not found"
    exit 1
  end
  
  processor = FileProcessor.new
  
  # Using Ruby 3.1+ shorthand hash syntax
  extraction_strategy = processor.determine_extraction_strategy(file_path)
  puts "Using extraction strategy: #{extraction_strategy}"
  
  result = processor.analyze_file(file_path)
  puts "Analysis result:"
  puts result.inspect
  
  # Example of continuing the conversation
  puts "\nWould you like to ask a follow-up question about the file? (y/n)"
  if gets.chomp.downcase == 'y'
    puts "Enter your follow-up question:"
    follow_up = gets.chomp
    
    # Assuming the conversation is stored in the result
    follow_up_response = result.conversation.send_message(follow_up)
    puts "Follow-up response:"
    puts follow_up_response.inspect
  end
end
