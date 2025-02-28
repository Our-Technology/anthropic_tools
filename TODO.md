# AnthropicTools To-Do List

## Medium Priority

### Add Documentation
- Create comprehensive YARD documentation for all classes
- Add detailed tutorials in the README
- Add examples for all new features

## Lower Priority

### Add ActiveRecord Integration
- Create a module for ActiveRecord models to easily become tools for Claude
- Include helpers for common CRUD operations on models

### Add Caching Layer
- Implement a caching strategy for tool results to improve performance
- Allow configuration of cache expiration and size

### Add Support for Retrieval
- Implement document retrieval capabilities
- Add vector store integrations for semantic search

### Add CI/CD Configuration
- Set up GitHub Actions for testing and releasing
- Add code quality checks (Rubocop, etc.)

### Advanced Features
- Implement message batches API for bulk processing
- Add tool router pattern for simplified tool handling
- Add raw response access for accessing headers and other metadata
- Add auto-pagination support for list endpoints
- Add configurable HTTP agent/client for proxies and custom networking
- Implement dynamic timeout calculation based on max_tokens

## Completed 

### Add Middleware Support
- Create a middleware system for request/response processing
- Allow users to easily add logging, metrics, or transformations
- Support custom HTTP client configuration (similar to TypeScript's fetch option)

### Add Instrumentation
- Add telemetry points for monitoring tool usage and performance
- Implement hooks for integration with monitoring systems
- Add debug mode for logging all requests and responses (similar to TypeScript's DEBUG=true)

### Add Specs for Core Functionality
- Add specs for error handling
- Add specs for token counting
- Add specs for configuration options
- Ensure all specs pass with proper mocking
- Implement VCR for recording and replaying real API interactions in tests
- Convert all API-calling specs to use VCR instead of WebMock stubs

### Improve Error Handling
- Add more specific error classes for different failure scenarios (similar to Python client)
- Implement automatic retry logic with exponential backoff
- Add better timeout handling for long-running requests
- Add connection error handling with automatic retries

### Add Features from Python/TypeScript Client
- Add token counting functionality (count_tokens method)
- Add usage information to responses (input_tokens, output_tokens)
- Implement improved streaming helpers with text_stream and get_final_message
- Add request_id to responses for better debugging
- Add timeout and retry configuration options
- Add stream cancellation support (similar to TypeScript's controller.abort())

### Update API Implementation
- Update client, tool, and conversation classes to match latest Anthropic API
- Add support for tool_choice parameter
- Improve content block handling
- Update specs to match new API structure

### Add Streaming Support
- Enhance the streaming capabilities with better error handling
- Add examples demonstrating streaming responses
