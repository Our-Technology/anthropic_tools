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

AnthropicTools provides robust support for Claude's tool use capabilities, allowing Claude to call functions in your application.

### Basic Example

```ruby
# Define a tool
weather_tool = AnthropicTools::Tool.new(
  name: 'get_weather',
  description: 'Get weather information for a specific location',
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

# Create a conversation with tools
conversation = AnthropicTools::Conversation.new(AnthropicTools.client)
conversation.add_tools(weather_tool)

# Send a message and get response with automatic tool execution
response = conversation.send("What's the weather in Chicago?")
puts response[:content]
```

For detailed documentation on tool use, including advanced usage, controlling tool behavior, and best practices, see [docs/tool_use.md](docs/tool_use.md).

## Middleware

AnthropicTools includes a middleware system for processing requests and responses. This allows you to add custom functionality such as logging, metrics collection, request/response transformation, and more.

```ruby
AnthropicTools.configure do |config|
  # Add logging middleware
  config.add_middleware(AnthropicTools::Middleware::Logging.new(
    logger: Rails.logger,
    level: :info
  ))
end
```

For detailed documentation on middleware, including examples and best practices, see [docs/middleware.md](docs/middleware.md).

## Instrumentation

AnthropicTools includes instrumentation for monitoring API usage and performance metrics.

```ruby
# Enable debug mode to use the LoggerMetricsCollector
AnthropicTools.configure do |config|
  config.debug = true # Uses LoggerMetricsCollector with Rails.logger
end

# Or set a specific metrics collector
AnthropicTools.configure do |config|
  config.metrics_collector = AnthropicTools::Instrumentation::LoggerMetricsCollector.new(
    logger: Rails.logger,
    level: :info
  )
end
```

For detailed documentation on instrumentation, including custom metrics collectors and best practices, see [docs/instrumentation.md](docs/instrumentation.md).

## Streaming

AnthropicTools provides support for streaming responses from Claude:

```ruby
client = AnthropicTools.client

# Basic streaming with a block
client.chat({ role: 'user', content: 'Write a short poem.' }, stream: true) do |chunk|
  if chunk['type'] == 'content_block_delta' && chunk['delta']['type'] == 'text'
    print chunk['delta']['text']
    $stdout.flush
  end
end

# Or use the improved streaming interface
stream = client.stream([{ role: 'user', content: 'Write a poem about Ruby.' }])
stream.on(:text) { |text| print text }
stream.start
```

For detailed documentation on streaming, including event handling and best practices, see [docs/streaming.md](docs/streaming.md).

## Additional Features

### Token Counting

```ruby
token_count = client.count_tokens({ role: 'user', content: 'Hello, Claude!' })
puts "Input tokens: #{token_count[:input_tokens]}"
```

### Error Handling

AnthropicTools provides detailed error classes for different types of API errors:

```ruby
begin
  response = client.chat({ role: 'user', content: 'Hello' })
rescue AnthropicTools::BadRequestError => e
  puts "Bad Request Error: #{e.message}"
  puts "Status code: #{e.status_code}"
  puts "Request ID: #{e.request_id}"
rescue AnthropicTools::RateLimitError => e
  puts "Rate limit exceeded. Retry after: #{e.headers['retry-after']}"
rescue AnthropicTools::AuthenticationError => e
  puts "Authentication error: Check your API key"
rescue AnthropicTools::PermissionDeniedError => e
  puts "Permission denied: #{e.message}"
rescue AnthropicTools::ServerError => e
  puts "Server error: #{e.message}"
rescue AnthropicTools::ApiError => e
  puts "API Error: #{e.message}"
end
```

### Retry Logic

AnthropicTools includes built-in retry logic for handling transient API errors. By default, it will retry on status codes 408, 429, 500, 502, 503, and 504 with exponential backoff.

```ruby
AnthropicTools.configure do |config|
  # Customize retry behavior
  config.max_retries = 5                                # Maximum retry attempts
  config.retry_initial_delay = 0.5                      # Initial delay in seconds
  config.retry_max_delay = 10.0                         # Maximum delay between retries
  config.retry_jitter = 0.25                            # Random jitter factor
  config.retry_statuses = [429, 500, 502, 503, 504]     # Status codes to retry
end
```

The retry mechanism uses exponential backoff with jitter to avoid overwhelming the API during outages.

### Dynamic Timeouts

AnthropicTools automatically calculates appropriate timeouts for large requests based on the `max_tokens` parameter:

```ruby
AnthropicTools.configure do |config|
  # Base timeout for regular requests
  config.timeout = 120 # 2 minutes
  
  # For requests with large max_tokens, a dynamic timeout is calculated
  # The formula is approximately: 60 minutes * tokens / 128,000
  # This ensures long-running generations don't time out prematurely
end

# The client will automatically use the dynamic timeout for requests with large max_tokens
response = client.chat(
  { role: 'user', content: 'Write a detailed essay.' },
  max_tokens: 8000 # Will get a longer timeout automatically
)
```

## Testing

AnthropicTools includes support for testing with VCR. For detailed documentation on testing, including VCR setup and best practices, see [docs/testing.md](docs/testing.md).

## Terminology

This gem aligns with Anthropic's API terminology:

- **Tool**: A capability that Claude can use, with a name, description, and input schema
- **ToolUse**: When Claude decides to use a tool, it creates a tool use request
- **ToolResult**: The result returned after processing a tool use request

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
