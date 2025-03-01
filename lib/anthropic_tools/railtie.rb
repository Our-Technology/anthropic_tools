require 'rails'

module AnthropicTools
  # Rails integration for AnthropicTools
  #
  # The Railtie class provides Rails integration for the AnthropicTools gem.
  # It sets up initializers, rake tasks, and generators to make it easier
  # to use AnthropicTools in a Rails application.
  #
  # This is automatically loaded when the gem is used in a Rails application.
  # No additional configuration is needed to enable the Rails integration.
  #
  # @example Using AnthropicTools in a Rails application
  #   # In your Gemfile
  #   gem 'anthropic_tools'
  #   
  #   # In an initializer (config/initializers/anthropic_tools.rb)
  #   AnthropicTools.configure do |config|
  #     config.api_key = ENV['ANTHROPIC_API_KEY']
  #     config.default_model = 'claude-3-opus-20240229'
  #   end
  class Railtie < Rails::Railtie
    # Initialize AnthropicTools in a Rails application
    #
    # @return [void]
    initializer "anthropic_tools.configure_rails_initialization" do
      # Add any Rails-specific initialization here
    end
    
    # Load rake tasks for AnthropicTools
    #
    # @return [void]
    rake_tasks do
      # Load rake tasks if needed
    end
    
    # Load generators for AnthropicTools
    #
    # @return [void]
    generators do
      require "generators/anthropic_tools/install_generator"
    end
  end
end
