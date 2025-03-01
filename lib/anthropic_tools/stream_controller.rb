module AnthropicTools
  # Controller for aborting streams
  #
  # The StreamController class provides a way to abort streaming responses
  # from the Anthropic API. It can be used to cancel a streaming response
  # that is in progress.
  #
  # @example Aborting a stream
  #   client = AnthropicTools::Client.new(api_key: ENV['ANTHROPIC_API_KEY'])
  #   
  #   stream = client.stream(
  #     messages: [{ role: 'user', content: 'Tell me a very long story.' }]
  #   )
  #   
  #   # In another thread or after some condition:
  #   stream.abort
  class StreamController
    # Create a new stream controller
    #
    # @return [StreamController] A new stream controller instance
    def initialize
      @aborted = false
    end
    
    # Abort the stream
    #
    # @return [void]
    def abort
      @aborted = true
    end
    
    # Check if the stream has been aborted
    #
    # @return [Boolean] Whether the stream has been aborted
    def aborted?
      @aborted
    end
  end
end
