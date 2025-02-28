# AnthropicTools Middleware

The middleware system in AnthropicTools provides a powerful way to intercept and modify requests and responses. This allows you to add custom functionality such as logging, metrics collection, request/response transformation, error handling, and more.

## How Middleware Works

Middleware in AnthropicTools follows a simple pipeline pattern:

1. Each middleware implements two key methods:
   - `before_request`: Called before a request is sent to the API
   - `after_response`: Called after a response is received from the API

2. Requests flow through middleware in the order they're added
3. Responses flow through middleware in reverse order
4. Each middleware can modify the request/response as needed

```
Request:  Client → Middleware 1 → Middleware 2 → Middleware 3 → API
Response: API → Middleware 3 → Middleware 2 → Middleware 1 → Client
```

## Built-in Middleware

AnthropicTools comes with several built-in middleware options:

### Logging Middleware

Logs requests and responses with customizable detail levels:

```ruby
AnthropicTools.configure do |config|
  # Add logging middleware
  config.add_middleware(AnthropicTools::Middleware::Logging.new(
    logger: Rails.logger,                # Use your application's logger
    level: :info,                        # Log level (:debug, :info, :warn, etc.)
    log_request_body: true,              # Include request bodies in logs
    log_response_body: false             # Exclude response bodies from logs
  ))
end
```

Example log output:
```
[2025-02-28T17:10:23] INFO: AnthropicTools Request: POST /v1/messages
[2025-02-28T17:10:23] INFO: Request Body: {"model":"claude-3-7-sonnet-20250219","messages":[{"role":"user","content":"Hello"}]}
[2025-02-28T17:10:25] INFO: AnthropicTools Response: Status 200 (1.85s)
```

### Metrics Middleware

Collects performance metrics for requests:

```ruby
# Create a metrics collector
metrics_collector = AnthropicTools::Instrumentation::LoggerMetricsCollector.new(
  logger: Rails.logger,
  level: :info
)

# Add metrics middleware
AnthropicTools.configure do |config|
  config.add_middleware(AnthropicTools::Middleware::Metrics.new(metrics_collector))
end
```

## Creating Custom Middleware

You can create custom middleware by inheriting from `AnthropicTools::Middleware::Base`:

### Request Modification Example

```ruby
# Add custom headers to all requests
class CustomHeaderMiddleware < AnthropicTools::Middleware::Base
  def initialize(headers = {})
    @headers = headers
  end

  def before_request(request)
    request[:headers] ||= {}
    @headers.each do |key, value|
      request[:headers][key] = value
    end
    request
  end

  def after_response(response)
    # No modifications needed for responses
    response
  end
end

# Add it to the configuration
AnthropicTools.configure do |config|
  config.add_middleware(CustomHeaderMiddleware.new({
    'X-Custom-Header' => 'custom-value',
    'X-Application-Name' => 'MyApp'
  }))
end
```

### Response Transformation Example

```ruby
# Add metadata to all responses
class ResponseMetadataMiddleware < AnthropicTools::Middleware::Base
  def before_request(request)
    # No modifications needed for requests
    request
  end

  def after_response(response)
    # Add timestamp and duration to all responses
    response[:_metadata] ||= {}
    response[:_metadata][:timestamp] = Time.now.iso8601
    response[:_metadata][:duration_ms] = (Time.now - response[:_request][:_start_time]) * 1000
    response
  end
end
```

### Error Handling Example

```ruby
# Retry failed requests with exponential backoff
class RetryMiddleware < AnthropicTools::Middleware::Base
  def initialize(max_retries: 3, retry_statuses: [429, 500, 502, 503, 504])
    @max_retries = max_retries
    @retry_statuses = retry_statuses
  end

  def before_request(request)
    # Initialize retry count
    request[:_retry_count] ||= 0
    request
  end

  def after_response(response)
    # Check if we should retry
    if @retry_statuses.include?(response[:status]) && response[:_request][:_retry_count] < @max_retries
      # Increment retry count
      response[:_request][:_retry_count] += 1
      
      # Calculate backoff time (exponential with jitter)
      backoff = (2 ** response[:_request][:_retry_count]) + rand(0.1..0.5)
      
      # Log the retry
      puts "Retrying request after #{backoff.round(2)}s (attempt #{response[:_request][:_retry_count]} of #{@max_retries})"
      
      # Sleep for backoff time
      sleep(backoff)
      
      # Make a new request (this would require access to the client)
      # For a real implementation, you'd need to integrate with the client
    end
    
    response
  end
end
```

## Combining Multiple Middleware

You can add multiple middleware to the stack, and they will be executed in order:

```ruby
AnthropicTools.configure do |config|
  # Add logging middleware first
  config.add_middleware(AnthropicTools::Middleware::Logging.new(logger: Rails.logger))
  
  # Then add metrics middleware
  config.add_middleware(AnthropicTools::Middleware::Metrics.new(metrics_collector))
  
  # Finally add custom headers middleware
  config.add_middleware(CustomHeaderMiddleware.new({'X-Application-Name' => 'MyApp'}))
end
```

## Best Practices

1. **Order matters**: Consider the order in which middleware are added. Logging middleware should typically be first so it can log the original request.

2. **Keep it simple**: Each middleware should have a single responsibility.

3. **Error handling**: Be careful with error handling in middleware. Unhandled exceptions will interrupt the middleware chain.

4. **Performance**: Middleware runs on every request, so keep performance in mind, especially for high-traffic applications.

## Implementation Details

### Middleware Base Class

The `AnthropicTools::Middleware::Base` class provides the foundation for all middleware:

```ruby
module AnthropicTools
  module Middleware
    class Base
      def before_request(request)
        # Default implementation: no-op
        request
      end

      def after_response(response)
        # Default implementation: no-op
        response
      end
    end
  end
end
```

### Middleware Stack

The `AnthropicTools::Middleware::Stack` class manages the execution of middleware:

```ruby
module AnthropicTools
  module Middleware
    class Stack
      def initialize
        @middlewares = []
      end

      def add(middleware)
        @middlewares << middleware
      end

      def empty?
        @middlewares.empty?
      end

      def process_request(request)
        @middlewares.reduce(request) do |req, middleware|
          middleware.before_request(req)
        end
      end

      def process_response(response)
        @middlewares.reverse.reduce(response) do |res, middleware|
          middleware.after_response(res)
        end
      end
    end
  end
end
```

## Testing Middleware

Here's an example of how to test custom middleware:

```ruby
RSpec.describe CustomHeaderMiddleware do
  it "adds custom headers to requests" do
    middleware = CustomHeaderMiddleware.new({
      'X-Custom-Header' => 'custom-value',
      'X-Application-Name' => 'TestApp'
    })
    
    request = { method: :post, url: '/test' }
    processed_request = middleware.before_request(request)
    
    expect(processed_request[:headers]['X-Custom-Header']).to eq('custom-value')
    expect(processed_request[:headers]['X-Application-Name']).to eq('TestApp')
  end
end
```
