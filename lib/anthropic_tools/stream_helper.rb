require_relative 'tool_use'
require 'json'

module AnthropicTools
  # Helper class for improved streaming interface
  #
  # The StreamHelper class provides methods for working with streaming responses
  # from the Anthropic API. It handles the details of processing streaming events,
  # accumulating content, and extracting the final message.
  #
  # @example Basic streaming
  #   client = AnthropicTools::Client.new(api_key: ENV['ANTHROPIC_API_KEY'])
  #   
  #   stream = client.stream(
  #     messages: [{ role: 'user', content: 'Tell me a story about a robot.' }]
  #   )
  #   
  #   # Process each event as it arrives
  #   stream.each do |event|
  #     puts event[:content][0][:text] if event[:content]
  #   end
  #
  # @example Getting the text stream
  #   client = AnthropicTools::Client.new(api_key: ENV['ANTHROPIC_API_KEY'])
  #   
  #   stream = client.stream(
  #     messages: [{ role: 'user', content: 'Tell me a story about a robot.' }]
  #   )
  #   
  #   # Process just the text as it arrives
  #   stream.text_stream do |text|
  #     print text
  #   end
  #
  # @example Getting the final message
  #   client = AnthropicTools::Client.new(api_key: ENV['ANTHROPIC_API_KEY'])
  #   
  #   stream = client.stream(
  #     messages: [{ role: 'user', content: 'Tell me a story about a robot.' }]
  #   )
  #   
  #   # Get the complete final message
  #   final_message = stream.final_message
  #   puts final_message[:content][0][:text]
  class StreamHelper
    # Create a new stream helper
    #
    # @param client [Client] The client instance
    # @param messages [Array] The messages to send
    # @param tools [Array] The tools to use
    # @param system [Hash] The system message
    # @param max_tokens [Integer] The maximum number of tokens
    # @param temperature [Float] The temperature for the model
    # @param tool_choice [String] The tool choice
    # @param disable_parallel_tool_use [Boolean] Whether to disable parallel tool use
    # @return [StreamHelper] A new stream helper instance
    def initialize(client, messages, tools, system, max_tokens, temperature, 
                  tool_choice, disable_parallel_tool_use)
      @client = client
      @messages = messages
      @tools = tools
      @system = system
      @max_tokens = max_tokens
      @temperature = temperature
      @tool_choice = tool_choice
      @disable_parallel_tool_use = disable_parallel_tool_use
      @controller = StreamController.new
      @handlers = {}
      @accumulated_text = ""
      @accumulated_response = nil
    end
    
    # Register event handlers
    #
    # @param event_type [Symbol] The event type
    # @yield [Hash] The event data
    # @return [StreamHelper] The stream helper instance
    def on(event_type, &block)
      @handlers[event_type.to_sym] = block
      self
    end
    
    # Start streaming and return final message
    #
    # @return [Hash] The final message
    def final_message
      stream_and_accumulate
      @accumulated_response
    end
    
    # Abort the stream
    #
    # @return [void]
    def abort
      @controller.abort
    end
    
    private
    
    # Stream and accumulate events
    #
    # @return [void]
    def stream_and_accumulate
      @accumulated_response = {
        content: "",
        content_blocks: [],
        tool_calls: []
      }
      
      @client.chat(@messages, tools: @tools, system: @system, 
                  max_tokens: @max_tokens, temperature: @temperature,
                  tool_choice: @tool_choice, 
                  disable_parallel_tool_use: @disable_parallel_tool_use,
                  stream: true) do |chunk|
        process_chunk(chunk)
        
        # Check if stream was aborted
        break if @controller.aborted?
      end
      
      @accumulated_response
    end
    
    # Process a chunk of data
    #
    # @param chunk [Hash] The chunk of data
    # @return [void]
    def process_chunk(chunk)
      # Handle different event types
      if chunk['type'] == 'content_block_start'
        handle_content_block_start(chunk)
      elsif chunk['type'] == 'content_block_delta'
        handle_content_block_delta(chunk)
      elsif chunk['type'] == 'content_block_stop'
        handle_content_block_stop(chunk)
      elsif chunk['type'] == 'message_start'
        handle_message_start(chunk)
      elsif chunk['type'] == 'message_delta'
        handle_message_delta(chunk)
      elsif chunk['type'] == 'message_stop'
        handle_message_stop(chunk)
      end
    end
    
    # Handle a content block start event
    #
    # @param chunk [Hash] The content block start event
    # @return [void]
    def handle_content_block_start(chunk)
      # Store content block info
      if chunk['content_block']['type'] == 'text'
        @accumulated_text = ""
      end
      
      # Call handler if registered
      if @handlers[:content_block_start]
        @handlers[:content_block_start].call(chunk['content_block'])
      end
    end
    
    # Handle a content block delta event
    #
    # @param chunk [Hash] The content block delta event
    # @return [void]
    def handle_content_block_delta(chunk)
      if chunk['delta']['type'] == 'text_delta'
        text = chunk['delta']['text']
        @accumulated_text += text
        
        # Call text handler if registered
        if @handlers[:text]
          @handlers[:text].call(text)
        end
      end
      
      # Call delta handler if registered
      if @handlers[:content_block_delta]
        @handlers[:content_block_delta].call(chunk['delta'])
      end
    end
    
    # Handle a content block stop event
    #
    # @param chunk [Hash] The content block stop event
    # @return [void]
    def handle_content_block_stop(chunk)
      # Add completed content block to accumulated response
      if chunk['content_block']['type'] == 'text'
        @accumulated_response[:content] += @accumulated_text
        @accumulated_response[:content_blocks] << {
          type: 'text',
          text: @accumulated_text
        }
      elsif chunk['content_block']['type'] == 'tool_use'
        tool_use = ToolUse.new(chunk['content_block'])
        @accumulated_response[:tool_calls] ||= []
        @accumulated_response[:tool_calls] << tool_use
        @accumulated_response[:content_blocks] << chunk['content_block']
      end
      
      # Call handler if registered
      if @handlers[:content_block_stop]
        @handlers[:content_block_stop].call(chunk['content_block'])
      end
    end
    
    # Handle a message start event
    #
    # @param chunk [Hash] The message start event
    # @return [void]
    def handle_message_start(chunk)
      # Initialize accumulated response with message metadata
      @accumulated_response[:id] = chunk['message']['id']
      @accumulated_response[:model] = chunk['message']['model']
      @accumulated_response[:role] = chunk['message']['role']
      
      # Call handler if registered
      if @handlers[:message_start]
        @handlers[:message_start].call(chunk['message'])
      end
    end
    
    # Handle a message delta event
    #
    # @param chunk [Hash] The message delta event
    # @return [void]
    def handle_message_delta(chunk)
      # Update usage information if available
      if chunk['delta']['usage']
        @accumulated_response[:usage] = chunk['delta']['usage']
      end
      
      # Call handler if registered
      if @handlers[:message_delta]
        @handlers[:message_delta].call(chunk['delta'])
      end
    end
    
    # Handle a message stop event
    #
    # @param chunk [Hash] The message stop event
    # @return [void]
    def handle_message_stop(chunk)
      # Set final message metadata
      @accumulated_response[:stop_reason] = chunk['message']['stop_reason']
      @accumulated_response[:usage] = chunk['message']['usage'] if chunk['message']['usage']
      
      # Call handler if registered
      if @handlers[:message_stop]
        @handlers[:message_stop].call(chunk['message'])
      end
    end
    
    # Create an on_data handler
    #
    # @yield [Hash] The parsed chunk
    # @return [Proc] The on_data handler
    def self.create_on_data_handler(&block)
      proc do |chunk, size|
        parsed_chunk = parse_chunk(chunk)
        if parsed_chunk
          block.call(parsed_chunk)
        end
      end
    end
    
    # Parse a chunk of data
    #
    # @param chunk [String] The chunk of data
    # @return [Hash] The parsed chunk
    def self.parse_chunk(chunk)
      # Skip empty chunks
      return nil if chunk.nil? || chunk.empty?
      
      # Handle data: [DONE] messages
      return nil if chunk.include?('data: [DONE]')
      
      # Extract the data part
      if chunk.start_with?('data: ')
        data = chunk.sub(/^data: /, '').strip
        
        # Parse the JSON data
        begin
          return JSON.parse(data, symbolize_names: true)
        rescue JSON::ParserError
          # Skip invalid JSON
          return nil
        end
      end
      
      nil
    end
  end
end
