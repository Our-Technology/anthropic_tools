module AnthropicTools
  class FunctionCall
    attr_reader :id, :name, :input

    def initialize(data)
      @id = data['id']
      @name = data['name']
      @input = data['input']
    end

    def to_h
      {
        id: id,
        name: name,
        input: input
      }
    end
  end
end
