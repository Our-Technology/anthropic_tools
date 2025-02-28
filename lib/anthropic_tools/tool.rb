module AnthropicTools
  class Tool
    attr_reader :name, :description, :input_schema, :implementation

    def initialize(name:, description:, parameters: nil, input_schema: nil, &implementation)
      @name = name
      @description = description
      @input_schema = input_schema || parameters # Support both parameters (legacy) and input_schema
      @implementation = implementation if block_given?
      
      validate_tool_definition
    end

    def to_h
      {
        name: name,
        description: description,
        input_schema: input_schema
      }
    end

    def call(params)
      if implementation
        implementation.call(params)
      else
        raise NotImplementedError, "No implementation provided for tool #{name}"
      end
    end
    
    private
    
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
