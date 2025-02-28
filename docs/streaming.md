# AnthropicTools Streaming

AnthropicTools provides robust support for streaming responses from Claude. Streaming is useful for creating more responsive applications, especially for longer responses or when implementing features like chat interfaces.

## How Streaming Works

When you use streaming with Claude:

1. The request is sent to the API with `stream: true`
2. Claude begins generating a response and sends it in chunks
3. Each chunk contains a portion of the response (text, tool use, etc.)
4. Your application processes these chunks as they arrive
5. The connection remains open until the response is complete

## Basic Streaming

The simplest way to use streaming is with a block:

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

## Improved Streaming Interface

For more control over streaming, AnthropicTools provides a `StreamController` class:

```ruby
# Create a stream controller
stream = client.stream(
  [{ role: 'user', content: 'Write a poem about Ruby.' }],
  max_tokens: 300
)

# Register event handlers
stream.on(:text) do |text|
  print text
  $stdout.flush
end

stream.on(:tool_use) do |tool_use|
  puts "\n[Tool Use Requested: #{tool_use['name']}]"
  
  # Process the tool use and provide a result
  result = process_tool(tool_use)
  stream.add_tool_result(tool_use['id'], result)
end

stream.on(:end) do |message|
  puts "\n\nMessage complete."
end

# Start the stream
stream.start

# Get the final message with all content
message = stream.final_message
puts "Usage: #{message[:usage].inspect}"

# You can also cancel a stream
stream.abort
```

## Stream Events

The `StreamController` provides several events you can listen for:

| Event | Description |
|-------|-------------|
| `:text` | Fired when text content is received |
| `:tool_use` | Fired when Claude requests to use a tool |
| `:content_block_start` | Fired when a new content block starts |
| `:content_block_delta` | Fired when a content block is updated |
| `:content_block_stop` | Fired when a content block is complete |
| `:message_start` | Fired when the message starts |
| `:message_delta` | Fired when the message is updated |
| `:message_stop` | Fired when the message is complete |
| `:error` | Fired when an error occurs |
| `:end` | Fired when the stream ends |

## Handling Tool Use in Streams

When Claude requests to use a tool in a streaming context, you can provide the tool result directly to the stream:

```ruby
stream.on(:tool_use) do |tool_use|
  # Process the tool use
  result = case tool_use['name']
  when 'get_weather'
    get_weather(tool_use['parameters']['location'])
  when 'search_database'
    search_database(tool_use['parameters']['query'])
  else
    { error: "Unknown tool: #{tool_use['name']}" }
  end
  
  # Provide the result back to the stream
  stream.add_tool_result(tool_use['id'], result)
end
```

## Middleware and Streaming

Middleware works with streaming just like with regular requests. The request goes through the middleware stack before being sent, and the final response goes through the middleware stack after the stream completes.

```ruby
AnthropicTools.configure do |config|
  # Add logging middleware
  config.add_middleware(AnthropicTools::Middleware::Logging.new(
    logger: Rails.logger,
    level: :info
  ))
end

# The middleware will log the request and the final response
client.chat(message, stream: true) do |chunk|
  # Process chunks...
end
```

## Best Practices

1. **Handle all event types**: Make sure your code handles all the different types of chunks that can be received.

2. **Flush output**: When displaying streamed text, remember to flush the output buffer to ensure text appears immediately.

3. **Error handling**: Add error handling to your stream processing code to gracefully handle connection issues.

4. **Tool timeouts**: When handling tool use in streams, implement timeouts to avoid blocking the stream indefinitely.

5. **UI considerations**: For web applications, consider using server-sent events (SSE) or WebSockets to stream responses to the client.

## Implementation Details

The streaming implementation uses Faraday's streaming capabilities:

```ruby
connection.post(url) do |req|
  req.headers = headers
  req.body = payload.to_json
  req.options.on_data = StreamHelper.create_on_data_handler(&block)
end
```

The `StreamHelper.create_on_data_handler` method creates a handler that parses each chunk of data and yields it to your block.

## Examples

### Web Application with ActionCable

```ruby
# In a Rails controller
def chat
  message = params[:message]
  
  # Start a background job to handle the streaming
  StreamingJob.perform_later(message, current_user.id)
  
  head :ok
end

# In a background job
class StreamingJob < ApplicationJob
  def perform(message, user_id)
    client = AnthropicTools.client
    
    client.chat({ role: 'user', content: message }, stream: true) do |chunk|
      if chunk['type'] == 'content_block_delta' && chunk['delta']['type'] == 'text'
        # Broadcast the chunk to the user's channel
        ActionCable.server.broadcast("user_#{user_id}", { 
          type: 'text', 
          content: chunk['delta']['text'] 
        })
      end
    end
    
    # Signal that the stream is complete
    ActionCable.server.broadcast("user_#{user_id}", { type: 'end' })
  end
end
```
