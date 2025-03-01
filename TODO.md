# AnthropicTools To-Do List

## Medium Priority

### Add Documentation
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

## Completed 

### Documentation Improvements
- ✅ Added comprehensive YARD documentation to the Railtie class
- ✅ Enhanced documentation for the StreamController class
- ✅ Added detailed parameter and return value documentation for API error classes
- ✅ Created comprehensive YARD documentation for classes

### Remove Redundant Classes
- ✅ Removed redundant FunctionCall and FunctionResponse classes
- ✅ Consolidated functionality into ToolUse and ToolResult classes
- ✅ Updated all tests to work with the new class structure
- ✅ Fixed client.rb to properly use instance variables for configuration
- ✅ Enhanced error handling to include request_id in all API errors

### Add Middleware Support
- ✅ Implemented middleware stack for request/response processing
- ✅ Added logging middleware for debugging
- ✅ Added metrics collection middleware
- ✅ Fixed middleware tests to ensure proper implementation of required methods
- ✅ Support custom HTTP client configuration

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

### Improve Documentation Structure
- Create dedicated documentation files for key features:
  - Created `docs/tool_use.md` for comprehensive tool use documentation
  - Created `docs/instrumentation.md` for detailed metrics collection guide
  - Created `docs/streaming.md` for in-depth streaming documentation
  - Created `docs/testing.md` for testing with VCR documentation
  - Maintained `docs/middleware.md` for middleware documentation
- Update README.md with concise information and links to detailed docs
- Add detailed examples for each feature in documentation files
