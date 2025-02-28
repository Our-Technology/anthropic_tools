# AnthropicTools To-Do List

## ✅ Update API Implementation
- ✅ Update client, tool, and conversation classes to match latest Anthropic API
- ✅ Add support for tool_choice parameter
- ✅ Improve content block handling
- ✅ Update specs to match new API structure

## Add ActiveRecord Integration
- Create a module for ActiveRecord models to easily become tools for Claude
- Include helpers for common CRUD operations on models

## ✅ Add Streaming Support
- ✅ Enhance the streaming capabilities with better error handling
- ✅ Add examples demonstrating streaming responses

## Add Caching Layer
- Implement a caching strategy for tool results to improve performance
- Allow configuration of cache expiration and size

## Add Middleware Support
- Create a middleware system for request/response processing
- Allow users to easily add logging, metrics, or transformations

## Improve Error Handling
- Add more specific error classes for different failure scenarios
- Implement automatic retry logic with exponential backoff

## Add Instrumentation
- Add telemetry points for monitoring tool usage and performance
- Implement hooks for integration with monitoring systems

## Create Rails Generators
- Add generators for common components (tools, controllers, etc.)
- Create a generator for a complete chat interface

## Add Support for Retrieval
- Implement document retrieval capabilities
- Add vector store integrations for semantic search

## Add Documentation
- Create comprehensive YARD documentation for all classes
- Add detailed tutorials in the README

## Add CI/CD Configuration
- Set up GitHub Actions for testing and releasing
- Add code quality checks (Rubocop, etc.)
