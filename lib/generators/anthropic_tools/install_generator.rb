require 'rails/generators/base'

module AnthropicTools
  module Generators
    class InstallGenerator < Rails::Generators::Base
      source_root File.expand_path('templates', __dir__)
      
      def create_initializer_file
        template "initializer.rb", "config/initializers/anthropic_tools.rb"
      end
      
      def show_readme
        readme "README" if behavior == :invoke
      end
    end
  end
end
