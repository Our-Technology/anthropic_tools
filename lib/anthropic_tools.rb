require 'anthropic_tools/version'
require 'anthropic_tools/configuration'
require 'anthropic_tools/client'
require 'anthropic_tools/message'
require 'anthropic_tools/tool'
require 'anthropic_tools/function_call'
require 'anthropic_tools/function_response'
require 'anthropic_tools/tool_use'
require 'anthropic_tools/tool_result'
require 'anthropic_tools/conversation'
require 'anthropic_tools/errors'
require 'anthropic_tools/file_helper'
require 'anthropic_tools/stream_helper'
require 'anthropic_tools/stream_controller'
require 'anthropic_tools/railtie' if defined?(Rails)

module AnthropicTools
  class << self
    attr_writer :configuration

    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield(configuration)
    end

    def client
      @client ||= Client.new(configuration)
    end
    
    def reset
      @configuration = Configuration.new
      @client = nil
    end
  end
end
