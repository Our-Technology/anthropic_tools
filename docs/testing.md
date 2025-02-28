# Testing with AnthropicTools

This document provides guidance on testing applications that use the AnthropicTools gem, with a focus on using VCR for recording and replaying HTTP interactions.

## Testing with VCR

VCR is a gem that records your test suite's HTTP interactions and replays them during future test runs. This is particularly useful for testing code that interacts with the Anthropic API, as it:

1. Makes tests faster by avoiding actual API calls
2. Makes tests more reliable by using consistent responses
3. Allows testing without an internet connection
4. Reduces the risk of hitting API rate limits during testing
5. Prevents incurring costs for API calls during testing

### Setting up VCR

First, add VCR and WebMock to your Gemfile:

```ruby
group :test do
  gem 'vcr'
  gem 'webmock'
end
```

Then configure VCR in your test setup:

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

### Using VCR in Your Tests

#### Basic Usage with RSpec

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

#### Testing Chat Functionality

```ruby
RSpec.describe "Chat API", :vcr do
  it "returns a response from Claude", vcr: { cassette_name: 'chat/simple_message' } do
    client = AnthropicTools.client
    message = AnthropicTools::Message.new(role: 'user', content: 'What is Ruby?')
    response = client.chat(message)
    
    expect(response).to include(:content)
    expect(response[:content]).to include("Ruby")
    expect(response[:role]).to eq("assistant")
  end
  
  it "handles tool use", vcr: { cassette_name: 'chat/tool_use' } do
    client = AnthropicTools.client
    
    # Define a tool
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
      { temperature: 22, conditions: 'Sunny', location: params['location'] }
    end
    
    # Create a conversation with the tool
    conversation = AnthropicTools::Conversation.new(client)
    conversation.add_tools(weather_tool)
    
    # Send a message that will trigger tool use
    response = conversation.send("What's the weather in Chicago?")
    
    expect(response[:content]).to include("Chicago")
    expect(response[:content]).to include("22")
    expect(response[:content]).to include("Sunny")
  end
end
```

### Re-recording Cassettes

When the API or your code changes, you may need to re-record your cassettes:

```ruby
# Delete a specific cassette
File.delete('spec/fixtures/vcr_cassettes/token_counting/basic.yml')

# Or delete all cassettes
FileUtils.rm_rf('spec/fixtures/vcr_cassettes')

# Then run your tests again to record new cassettes
```

You can also use VCR's record modes:

```ruby
it "counts tokens correctly", vcr: { cassette_name: 'token_counting/basic', record: :new_episodes } do
  # This will record a new interaction if the existing one doesn't match
end
```

## Mocking Responses

For unit tests where you want to avoid VCR, you can mock the AnthropicTools client:

```ruby
RSpec.describe MyService do
  let(:client) { instance_double(AnthropicTools::Client) }
  let(:service) { MyService.new(client) }
  
  before do
    allow(client).to receive(:chat).and_return({
      role: 'assistant',
      content: 'Mocked response',
      _request_id: 'req_mock123'
    })
  end
  
  it "processes Claude's response" do
    result = service.process_with_claude("Hello")
    expect(result).to include("Mocked response")
  end
end
```

## Testing Middleware

When testing middleware, you can create a simple test harness:

```ruby
RSpec.describe MyCustomMiddleware do
  let(:middleware) { MyCustomMiddleware.new }
  let(:stack) { AnthropicTools::Middleware::Stack.new }
  
  before do
    stack.add(middleware)
  end
  
  it "modifies requests correctly" do
    request = { method: :post, url: '/test', headers: {} }
    processed_request = stack.process_request(request)
    
    expect(processed_request[:headers]).to include('X-Custom-Header')
  end
  
  it "modifies responses correctly" do
    response = { 
      status: 200, 
      body: '{"content":"test"}',
      _request: { method: :post, url: '/test' }
    }
    processed_response = stack.process_response(response)
    
    expect(processed_response).to include(:_metadata)
  end
end
```

## Testing Streaming

Testing streaming responses requires a bit more setup:

```ruby
RSpec.describe "Streaming", :vcr do
  it "processes streamed chunks", vcr: { cassette_name: 'streaming/basic' } do
    client = AnthropicTools.client
    chunks = []
    
    client.chat({ role: 'user', content: 'Count to 3 briefly.' }, stream: true) do |chunk|
      chunks << chunk
    end
    
    # Check that we received chunks
    expect(chunks).not_to be_empty
    
    # Check that we got text content
    text_chunks = chunks.select do |chunk| 
      chunk['type'] == 'content_block_delta' && chunk['delta']['type'] == 'text'
    end
    expect(text_chunks).not_to be_empty
    
    # Check that the content includes counting
    all_text = text_chunks.map { |chunk| chunk['delta']['text'] }.join
    expect(all_text).to match(/1.*2.*3/)
  end
end
```

## Best Practices

1. **Filter sensitive data**: Always filter API keys and other sensitive data from your VCR cassettes.

2. **Use descriptive cassette names**: Organize cassettes with descriptive names that reflect the test's purpose.

3. **Match on request body**: When testing with different payloads, ensure VCR matches on the request body.

4. **Commit cassettes to version control**: VCR cassettes should be committed to version control so all developers have the same test environment.

5. **Periodically refresh cassettes**: Refresh your cassettes periodically to ensure they reflect the current API behavior.

6. **Test error conditions**: Create cassettes for error conditions by temporarily modifying your API key or requests.

7. **Use separate cassettes for different test environments**: If you test against different environments (e.g., staging vs. production), use separate cassette directories.

## Troubleshooting

### VCR Not Recording

If VCR isn't recording new interactions:

1. Check that `record: :new_episodes` is set
2. Ensure WebMock is properly configured
3. Verify that the request doesn't match an existing cassette

### Inconsistent Test Results

If tests pass locally but fail in CI:

1. Ensure all developers are using the same VCR configuration
2. Check that all cassettes are committed to version control
3. Verify that the CI environment has the necessary environment variables

### API Changes

If the API changes and your tests start failing:

1. Delete the affected cassettes
2. Re-run your tests to record new interactions
3. Update your test expectations to match the new response format
