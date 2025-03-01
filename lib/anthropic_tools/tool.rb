module AnthropicTools
  # Class for defining tools that Claude can use
  #
  # The Tool class provides a way to define tools that Claude can use to perform
  # actions or retrieve information. Tools have a name, description, and an input
  # schema that defines the parameters they accept.
  #
  # @example Creating a simple tool
  #   weather_tool = AnthropicTools::Tool.new(
  #     name: 'get_weather',
  #     description: 'Get the current weather for a location',
  #     input_schema: {
  #       type: 'object',
  #       properties: {
  #         location: { type: 'string', description: 'City and state, e.g. San Francisco, CA' }
  #       },
  #       required: ['location']
  #     }
  #   )
  #
  # @example Using a tool with the client
  #   client = AnthropicTools::Client.new(api_key: ENV['ANTHROPIC_API_KEY'])
  #   
  #   response = client.chat(
  #     messages: [{ role: 'user', content: 'What is the weather in San Francisco?' }],
  #     tools: [weather_tool.to_h],
  #     tool_choice: 'auto'
  #   )
  class Tool
    # @return [String] The name of the tool
    # @return [String] The description of the tool
    # @return [Hash] The input schema for the tool
    attr_reader :name, :description, :input_schema, :implementation

    # Create a new tool
    #
    # @param name [String] The name of the tool
    # @param description [String] The description of the tool
    # @param parameters [Hash] The parameters for the tool (legacy)
    # @param input_schema [Hash] The input schema for the tool
    # @param implementation [Proc] The implementation of the tool
    # @return [Tool] A new tool instance
    def initialize(name:, description:, parameters: nil, input_schema: nil, &implementation)
      @name = name
      @description = description
      @input_schema = input_schema || parameters # Support both parameters (legacy) and input_schema
      @implementation = implementation if block_given?
      
      validate_tool_definition
    end

    # Convert the tool to a hash for API requests
    #
    # @return [Hash] The tool as a hash
    def to_h
      {
        name: name,
        description: description,
        input_schema: input_schema
      }
    end

    # Call the tool with the given parameters
    #
    # @param params [Hash] The parameters to pass to the tool
    # @return [Object] The result of the tool call
    def call(params)
      if implementation
        implementation.call(params)
      else
        raise NotImplementedError, "No implementation provided for tool #{name}"
      end
    end
    
    private
    
    # Validate the tool definition
    #
    # @raise [ArgumentError] If the tool name, description, or input schema is invalid
    def validate_tool_definition
      raise ArgumentError, "Tool name is required" if name.nil? || name.empty?
      raise ArgumentError, "Tool description is required" if description.nil? || description.empty?
      raise ArgumentError, "Tool input_schema is required" if input_schema.nil?
      
      # Encourage detailed descriptions
      if description.split(/\s+/).size < 10
        warn "Warning: Tool '#{name}' has a short description. Detailed descriptions improve Claude's understanding of the tool."
      end
    end
  end
end
