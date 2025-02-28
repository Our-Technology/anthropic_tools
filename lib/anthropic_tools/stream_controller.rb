module AnthropicTools
  # Controller for aborting streams
  class StreamController
    def initialize
      @aborted = false
    end
    
    def abort
      @aborted = true
    end
    
    def aborted?
      @aborted
    end
  end
end
