lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "anthropic_tools/version"

Gem::Specification.new do |spec|
  spec.name          = "anthropic_tools"
  spec.version       = AnthropicTools::VERSION
  spec.authors       = ["Neighbor Solutions"]
  spec.email         = ["dev@neighbor.solutions"]

  spec.summary       = "Ruby on Rails library for Anthropic API tool usage"
  spec.description   = "Interact with Anthropic's Claude models with tool use capabilities"
  spec.homepage      = "https://github.com/our-technology/anthropic_tools"
  spec.license       = "MIT"
  spec.required_ruby_version = Gem::Requirement.new(">= 3.2.2")

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  spec.files = Dir.glob("{bin,lib}/**/*") + %w[LICENSE.txt README.md CHANGELOG.md]
  
  spec.require_paths = ["lib"]

  spec.add_dependency "faraday", "~> 2.0"
  spec.add_dependency "faraday-retry", "~> 2.0"
  
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "yard", "~> 0.9"
end
