# AnthropicTools Tool Use

This document provides detailed information about using Claude's tool use capabilities with the AnthropicTools gem. Tool use allows Claude to call functions in your application to retrieve information or perform actions.

## How Tool Use Works

When using tools with Claude:

1. You define tools with a name, description, and input schema
2. You send these tool definitions along with your message to Claude
3. Claude decides when to use a tool and generates a tool use request
4. Your application processes the tool use request and returns a result
5. Claude incorporates the result into its response

## Defining Tools

Tools are defined using the `AnthropicTools::Tool` class:

```ruby
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

### Tool Components

Each tool has several key components:

1. **Name**: A unique identifier for the tool (e.g., `get_weather`)
2. **Description**: A detailed explanation of what the tool does
3. **Input Schema**: A JSON Schema defining the expected parameters
4. **Implementation**: A block that processes the parameters and returns a result

### Input Schema

The input schema uses JSON Schema format to define the parameters:

```ruby
input_schema: {
  type: 'object',
  properties: {
    query: {
      type: 'string',
      description: 'Search query'
    },
    limit: {
      type: 'integer',
      description: 'Maximum number of results',
      default: 10
    }
  },
  required: ['query']
}
```

### Tool Implementation

The implementation block receives the parameters and returns a result:

```ruby
search_tool = AnthropicTools::Tool.new(
  name: 'search_database',
  description: 'Search the database for information',
  input_schema: { ... }
) do |params|
  query = params['query']
  limit = params['limit'] || 10
  
  # Perform the search
  results = Database.search(query, limit: limit)
  
  # Return the results
  {
    results: results,
    count: results.length,
    query: query
  }
end
```

## Using Tools in Conversations

The easiest way to use tools is with the `Conversation` class:

```ruby
# Create a conversation with tools
conversation = AnthropicTools::Conversation.new(AnthropicTools.client)
conversation.add_tools(weather_tool, search_tool)

# Send a message and get response with automatic tool execution
response = conversation.send("What's the weather in Chicago?")
puts response[:content]
```

## Using Tools Directly with the Client

You can also use tools directly with the client:

```ruby
client = AnthropicTools.client

# Define your tools
tools = [weather_tool, search_tool]

# Send a message with tools
message = AnthropicTools::Message.new(role: 'user', content: "What's the weather in Chicago?")
response = client.chat(message, tools: tools)

# Check if the response includes tool calls
if response[:tool_calls]
  # Process each tool call
  tool_results = response[:tool_calls].map do |tool_call|
    tool_name = tool_call[:name]
    tool_params = tool_call[:parameters]
    tool_id = tool_call[:id]
    
    # Find the matching tool
    tool = tools.find { |t| t.name == tool_name }
    
    # Call the tool
    result = tool.call(tool_params)
    
    # Create a tool result
    AnthropicTools::ToolResult.new(
      tool_use_id: tool_id,
      content: result
    )
  end
  
  # Send a follow-up message with the tool results
  follow_up_message = AnthropicTools::Message.new(
    role: 'user',
    content: 'Here are the results',
    tool_results: tool_results
  )
  
  final_response = client.chat([message, response, follow_up_message])
  puts final_response[:content]
else
  puts response[:content]
end
```

## Controlling Tool Use

You can control how Claude uses tools with additional parameters:

### Tool Choice

The `tool_choice` parameter controls whether and which tools Claude should use:

```ruby
# Force Claude to use any tool
response = conversation.send("Tell me about the weather somewhere nice.", 
                           tool_choice: { type: 'any' })

# Force Claude to use a specific tool
response = conversation.send("I need weather information.", 
                           tool_choice: { 
                             type: 'tool', 
                             name: 'get_weather' 
                           })

# Prevent Claude from using tools
response = conversation.send("Just chat with me, no tools needed.", 
                           tool_choice: { type: 'none' })
```

### Parallel Tool Use

By default, Claude can use multiple tools in parallel. You can disable this:

```ruby
# Prevent parallel tool use
response = conversation.send("Compare the weather in multiple cities.", 
                           disable_parallel_tool_use: true)
```

## Handling Tool Errors

You can indicate that a tool encountered an error:

```ruby
weather_tool = AnthropicTools::Tool.new(
  name: 'get_weather',
  description: 'Get weather information',
  input_schema: { ... }
) do |params|
  begin
    # Try to get weather data
    WeatherAPI.get(params['location'])
  rescue => e
    # Return an error
    AnthropicTools::ToolResult.error(
      "Failed to get weather data: #{e.message}"
    )
  end
end
```

When using the client directly:

```ruby
# Create an error result
error_result = AnthropicTools::ToolResult.new(
  tool_use_id: tool_id,
  content: "Location not found",
  is_error: true
)
```

## Advanced Tool Use

### Streaming with Tools

Tools can be used with streaming responses:

```ruby
stream = client.stream(
  [{ role: 'user', content: 'What\'s the weather in Chicago?' }],
  tools: [weather_tool]
)

stream.on(:tool_use) do |tool_use|
  # Process the tool use
  result = case tool_use['name']
  when 'get_weather'
    get_weather(tool_use['parameters']['location'])
  else
    { error: "Unknown tool: #{tool_use['name']}" }
  end
  
  # Provide the result back to the stream
  stream.add_tool_result(tool_use['id'], result)
end

stream.on(:text) do |text|
  print text
end

stream.start
```

### Complex Tool Implementations

For more complex tools, you can separate the definition from the implementation:

```ruby
# Define the tool
database_tool = AnthropicTools::Tool.new(
  name: 'query_database',
  description: 'Query the database using SQL',
  input_schema: {
    type: 'object',
    properties: {
      sql: {
        type: 'string',
        description: 'SQL query to execute'
      }
    },
    required: ['sql']
  }
)

# Implement the tool separately
class DatabaseToolHandler
  def self.handle(params)
    sql = params['sql']
    
    # Validate the SQL (prevent injection)
    unless valid_sql?(sql)
      return { error: "Invalid SQL query" }
    end
    
    # Execute the query
    begin
      results = ActiveRecord::Base.connection.execute(sql).to_a
      { results: results, count: results.length }
    rescue => e
      { error: "Database error: #{e.message}" }
    end
  end
  
  def self.valid_sql?(sql)
    # Implement SQL validation
    !sql.downcase.include?('drop') && !sql.downcase.include?('delete')
  end
end

# Connect the tool to its implementation
database_tool.implementation = ->(params) { DatabaseToolHandler.handle(params) }
```

## Best Practices

1. **Detailed descriptions**: Provide detailed descriptions for your tools and parameters to help Claude use them correctly.

2. **Input validation**: Validate input parameters before processing to prevent errors.

3. **Error handling**: Always handle potential errors in your tool implementations.

4. **Security**: Be cautious with tools that modify data or execute code, as Claude might use them in unexpected ways.

5. **Timeouts**: Implement timeouts for tools that make external API calls.

6. **Logging**: Log tool usage for debugging and monitoring.

7. **Testing**: Create comprehensive tests for your tools, including error cases.

## Terminology

- **Tool**: A capability that Claude can use, with a name, description, and input schema
- **ToolUse**: When Claude decides to use a tool, it creates a tool use request
- **ToolResult**: The result returned after processing a tool use request

## Examples

### Weather Tool

```ruby
weather_tool = AnthropicTools::Tool.new(
  name: 'get_weather',
  description: 'Get weather information for a location',
  input_schema: {
    type: 'object',
    properties: {
      location: { type: 'string' }
    },
    required: ['location']
  }
) do |params|
  location = params['location']
  
  # In a real implementation, you would call a weather API
  case location.downcase
  when /chicago/
    { temperature: 18, conditions: 'Windy', location: 'Chicago, IL' }
  when /new york/
    { temperature: 22, conditions: 'Cloudy', location: 'New York, NY' }
  when /san francisco/
    { temperature: 20, conditions: 'Foggy', location: 'San Francisco, CA' }
  else
    { temperature: 25, conditions: 'Sunny', location: location }
  end
end
```

### Database Search Tool

```ruby
search_tool = AnthropicTools::Tool.new(
  name: 'search_products',
  description: 'Search for products in the database',
  input_schema: {
    type: 'object',
    properties: {
      query: { 
        type: 'string',
        description: 'Search query'
      },
      category: {
        type: 'string',
        description: 'Product category',
        enum: ['electronics', 'clothing', 'food', 'all'],
        default: 'all'
      },
      limit: {
        type: 'integer',
        description: 'Maximum number of results',
        default: 5
      }
    },
    required: ['query']
  }
) do |params|
  query = params['query']
  category = params['category'] || 'all'
  limit = params['limit'] || 5
  
  # In a real implementation, you would query your database
  products = if category == 'all'
    Product.where("name LIKE ?", "%#{query}%").limit(limit)
  else
    Product.where(category: category).where("name LIKE ?", "%#{query}%").limit(limit)
  end
  
  {
    results: products.map { |p| { id: p.id, name: p.name, price: p.price } },
    count: products.count,
    query: query,
    category: category
  }
end
```
