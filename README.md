# AnthropicTools

A Ruby on Rails library to leverage Anthropic's Claude models with tool use capabilities.

## Installation

Add this to your Gemfile:

```ruby
gem 'anthropic_tools', git: 'https://github.com/our-technology/anthropic_tools.git'
```

Then run:

```bash
bundle install
```

## Requirements

- Ruby 3.2.2 or higher
- Rails 6.0 or higher (for Rails integration)

## Setup

Generate an initializer:

```bash
rails generate anthropic_tools:install
```

This will create a configuration file at `config/initializers/anthropic_tools.rb`.

## Configuration

```ruby
AnthropicTools.configure do |config|
  config.api_key = ENV['ANTHROPIC_API_KEY'] # Your Anthropic API key
  config.model = 'claude-3-opus-20240229' # Default model
  
  # Timeout and retry settings
  config.timeout = 60 # 60 seconds timeout
  config.max_retries = 3 # Retry up to 3 times
  config.retry_initial_delay = 1.0 # Start with 1 second delay
  config.retry_max_delay = 8.0 # Maximum delay between retries
  config.retry_jitter = 0.25 # Add randomness to retry timing
  config.retry_statuses = [408, 429, 500, 502, 503, 504] # Status codes to retry
end
```

For long-running requests with large `max_tokens`, the client will automatically calculate an appropriate timeout.

## Basic Usage

### Simple Message

```ruby
# Initialize client
client = AnthropicTools.client

# Send a simple message
message = AnthropicTools::Message.new(role: 'user', content: 'Hello Claude!')
response = client.chat(message)
puts response[:content]

# Access request ID for debugging
puts "Request ID: #{response[:_request_id]}"
```

### Conversations

```ruby
# Create a conversation to maintain history
conversation = AnthropicTools::Conversation.new(AnthropicTools.client)

# First turn
response = conversation.send("What's the weather in Chicago?")
puts "Claude: #{response[:content]}"

# Second turn (conversation history is maintained)
response = conversation.send("How about in New York?")
puts "Claude: #{response[:content]}"
```

## Tool Use

### Defining Tools

```ruby
# Define a tool
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
  # Implement weather lookup here
  { temperature: 22, conditions: 'Sunny', location: params['location'] }
end
```

### Using Tools in Conversations

```ruby
# Create a conversation with tools
conversation = AnthropicTools::Conversation.new(AnthropicTools.client)
conversation.add_tools(weather_tool)

# Send a message and get response with automatic tool execution
response = conversation.send("What's the weather in Chicago?")
puts response[:content]
```

### Controlling Tool Use

```ruby
# Force Claude to use any tool
response = conversation.send("Tell me about the weather somewhere nice.", 
                           tool_choice: { type: 'any' })

# Prevent parallel tool use
response = conversation.send("Compare the weather in multiple cities.", 
                           disable_parallel_tool_use: true)

# Force Claude to use a specific tool
response = conversation.send("I need weather information.", 
                           tool_choice: { 
                             type: 'tool', 
                             name: 'get_weather' 
                           })
```

## Streaming

### Basic Streaming

```ruby
# Initialize client
client = AnthropicTools.client

# Send a message with streaming enabled
message = AnthropicTools::Message.new(role: 'user', content: 'Write a short poem.')

client.chat(message, stream: true) do |chunk|
  case chunk['type']
  when 'content_block_delta'
    if chunk['delta']['type'] == 'text'
      print chunk['delta']['text']
      $stdout.flush  # Ensure text is displayed immediately
    end
  when 'content_block_start'
    if chunk['content_block']['type'] == 'tool_use'
      puts "\n[Tool Use Requested: #{chunk['content_block']['tool_use']['name']}]"
    end
  when 'message_delta'
    puts "\n\nMessage complete." if chunk['delta']['stop_reason'] == 'end_turn'
  end
end
```

### Improved Streaming Interface

```ruby
stream = client.stream(
  [{ role: 'user', content: 'Write a poem about Ruby.' }],
  max_tokens: 300
)

# Register event handlers
stream.on(:text) do |text|
  print text
  $stdout.flush
end

# Get the final message with all content
message = stream.final_message
puts "Usage: #{message[:usage].inspect}"

# You can also cancel a stream
stream.abort
```

## Additional Features

### Token Counting

```ruby
token_count = client.count_tokens({ role: 'user', content: 'Hello, Claude!' })
puts "Input tokens: #{token_count[:input_tokens]}"
```

### Error Handling

```ruby
begin
  response = client.chat({ role: 'user', content: 'Hello' })
rescue AnthropicTools::BadRequestError => e
  puts "Bad Request Error: #{e.message}"
  puts "Status code: #{e.status_code}"
  puts "Request ID: #{e.request_id}"
rescue AnthropicTools::ApiError => e
  puts "API Error: #{e.message}"
end
```

## Testing with VCR

This gem includes VCR cassettes for testing, which record and replay HTTP interactions with the Anthropic API. This allows you to run tests without making actual API calls.

### Setting up VCR in your tests

```ruby
require 'vcr'
require 'webmock/rspec'

VCR.configure do |config|
  config.cassette_library_dir = "spec/fixtures/vcr_cassettes"
  config.hook_into :webmock
  config.configure_rspec_metadata!
  
  # Filter out sensitive data
  config.filter_sensitive_data('<ANTHROPIC_API_KEY>') { ENV['ANTHROPIC_API_KEY'] }
  
  # Allow VCR to record new HTTP interactions when no cassette exists
  config.default_cassette_options = {
    record: :new_episodes,
    match_requests_on: [:method, :uri, :body]
  }
end
```

### Using VCR in your specs

```ruby
RSpec.describe "Token Counting", :vcr do
  it "counts tokens correctly", vcr: { cassette_name: 'token_counting/basic' } do
    client = AnthropicTools.client
    result = client.count_tokens([{ role: 'user', content: 'Hello, Claude!' }])
    
    expect(result).to include(:input_tokens)
    expect(result[:input_tokens]).to be_a(Integer)
  end
end
```

## Terminology

This gem aligns with Anthropic's API terminology:

- **Tool**: A capability that Claude can use, with a name, description, and input schema
- **ToolUse**: When Claude decides to use a tool, it creates a tool use request
- **ToolResult**: The result returned after processing a tool use request

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
