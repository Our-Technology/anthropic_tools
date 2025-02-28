require_relative 'tool_use'

module AnthropicTools
  # Helper class for improved streaming interface
  class StreamHelper
    attr_reader :client, :messages, :tools, :system, :max_tokens, :temperature, 
                :tool_choice, :disable_parallel_tool_use, :controller
    
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
    def on(event_type, &block)
      @handlers[event_type.to_sym] = block
      self
    end
    
    # Start streaming and return final message
    def final_message
      stream_and_accumulate
      @accumulated_response
    end
    
    # Abort the stream
    def abort
      @controller.abort
    end
    
    private
    
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
    
    def handle_message_stop(chunk)
      # Set final message metadata
      @accumulated_response[:stop_reason] = chunk['message']['stop_reason']
      @accumulated_response[:usage] = chunk['message']['usage'] if chunk['message']['usage']
      
      # Call handler if registered
      if @handlers[:message_stop]
        @handlers[:message_stop].call(chunk['message'])
      end
    end
  end
end
