module AnthropicTools
  class Tool
    attr_reader :name, :description, :parameters, :implementation

    def initialize(name:, description:, parameters:, &implementation)
      @name = name
      @description = description
      @parameters = parameters
      @implementation = implementation if block_given?
    end

    def to_h
      {
        name: name,
        description: description,
        input_schema: parameters
      }
    end

    def call(params)
      if implementation
        implementation.call(params)
      else
        raise NotImplementedError, "No implementation provided for tool #{name}"
      end
    end
  end
end
