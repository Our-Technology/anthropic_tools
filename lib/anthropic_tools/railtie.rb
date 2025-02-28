require 'rails'

module AnthropicTools
  class Railtie < Rails::Railtie
    initializer "anthropic_tools.configure_rails_initialization" do
      # Add any Rails-specific initialization here
    end
    
    rake_tasks do
      # Load rake tasks if needed
    end
    
    generators do
      require "generators/anthropic_tools/install_generator"
    end
  end
end
