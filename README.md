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

## Usage

### Basic Example

```ruby
# Initialize client
client = AnthropicTools.client

# Send a simple message
message = { role: 'user', content: 'Hello Claude!' }
response = client.chat(message)
puts response[:content]
```

### Streaming Example

```ruby
# Initialize client
client = AnthropicTools.client

# Send a message with streaming enabled
message = { role: 'user', content: 'Write a short poem.' }

client.chat(message, stream: true) do |chunk|
  case chunk['type']
  when 'content_block_delta'
    print chunk['delta']['text']
    $stdout.flush  # Ensure text is displayed immediately
  when 'message_delta'
    puts "\n\nMessage complete." if chunk['delta']['stop_reason'] == 'end_turn'
  end
end
```

### Working with Tools

```ruby
# Define a tool
weather_tool = AnthropicTools::Tool.new(
  name: 'get_weather',
  description: 'Get current weather for a location',
  parameters: {
    type: 'object',
    properties: {
      location: {
        type: 'string',
        description: 'City name'
      }
    },
    required: ['location']
  }
) do |params|
  # Implement weather lookup here
  { temperature: 22, conditions: 'Sunny', location: params['location'] }
end

# Create a conversation with tools
conversation = AnthropicTools.client.create_conversation
conversation.add_tools(weather_tool)

# Send a message and get response with automatic tool execution
response = conversation.send("What's the weather in Chicago?")
puts response[:content]
```

### Supporting Multiple Turns

```ruby
conversation = AnthropicTools.client.create_conversation(
  system: "You are a helpful assistant with access to tools."
)

# Add multiple tools
conversation.add_tools(weather_tool, database_tool)

# First turn
response = conversation.send("What's the weather in Chicago?")
puts "Claude: #{response[:content]}"

# Second turn (conversation history is maintained)
response = conversation.send("How about in New York?")
puts "Claude: #{response[:content]}"
```

## Terminology

This gem aligns with Anthropic's API terminology:

- **Tool**: A capability that Claude can use, with a name, description, and input schema
- **ToolUse**: When Claude decides to use a tool, it creates a tool use request
- **ToolResult**: The result returned after processing a tool use request

## Advanced Usage

See the documentation for more advanced use cases, including:

- Stream responses
- File processing
- ActiveRecord integration
- Background job processing
- Real-time updates via WebSockets

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
