require 'spec_helper'

RSpec.describe AnthropicTools::Middleware do
  describe AnthropicTools::Middleware::Stack do
    let(:stack) { described_class.new }
    
    it "starts empty" do
      expect(stack.empty?).to be true
    end
    
    it "processes requests through middleware" do
      middleware = double("Middleware", before_request: nil, after_response: nil)
      expect(middleware).to receive(:before_request).with({ url: '/test' }).and_return({ url: '/modified' })
      
      stack.add(middleware)
      result = stack.process_request({ url: '/test' })
      
      expect(result).to eq({ url: '/modified' })
    end
    
    it "processes responses through middleware in reverse order" do
      middleware1 = double("Middleware1", before_request: nil, after_response: nil)
      middleware2 = double("Middleware2", before_request: nil, after_response: nil)
      
      # Set up the expectations in reverse order since we're testing the reverse processing
      expect(middleware2).to receive(:after_response).with({ status: 200 }).and_return({ status: 201 })
      expect(middleware1).to receive(:after_response).with({ status: 201 }).and_return({ status: 202 })
      
      stack.add(middleware1)
      stack.add(middleware2)
      
      result = stack.process_response({ status: 200 })
      expect(result).to eq({ status: 202 })
    end
    
    it "returns the request unchanged when the stack is empty" do
      request = { url: '/test', method: :post }
      result = stack.process_request(request)
      
      expect(result).to eq(request)
      expect(result).to be(request) # Same object, not just equal
    end
    
    it "returns the response unchanged when the stack is empty" do
      response = { status: 200, body: '{"result": "success"}' }
      result = stack.process_response(response)
      
      expect(result).to eq(response)
      expect(result).to be(response) # Same object, not just equal
    end
  end
  
  describe AnthropicTools::Middleware::Logging do
    let(:logger) { instance_double(Logger) }
    let(:middleware) { described_class.new(logger: logger) }
    
    it "logs requests" do
      expect(logger).to receive(:info).with(/AnthropicTools Request: POST \/test/)
      
      request = { method: :post, url: '/test', _start_time: Time.now }
      middleware.before_request(request)
    end
    
    it "logs responses" do
      expect(logger).to receive(:info).with(/AnthropicTools Response: Status 200/)
      
      response = { 
        status: 200, 
        _request: { _start_time: Time.now - 1 }
      }
      middleware.after_response(response)
    end
    
    it "redacts sensitive information" do
      expect(logger).to receive(:info).with(/AnthropicTools Request: POST \/test/)
      expect(logger).to receive(:info) do |message|
        expect(message).to include('Request Body:')
        expect(message).to include('"api_key":"[REDACTED]"')
      end
      
      middleware = described_class.new(logger: logger, log_request_body: true)
      request = { 
        method: :post, 
        url: '/test', 
        body: '{"api_key":"secret-key"}',
        _start_time: Time.now 
      }
      middleware.before_request(request)
    end
  end

  describe "Custom middleware examples" do
    # Example 1: Custom header middleware
    class CustomHeaderMiddleware < AnthropicTools::Middleware::Base
      def initialize(headers = {})
        @headers = headers
      end

      def before_request(request)
        request[:headers] ||= {}
        @headers.each do |key, value|
          request[:headers][key] = value
        end
        request
      end

      def after_response(response)
        response
      end
    end

    it "adds custom headers to requests" do
      middleware = CustomHeaderMiddleware.new({
        'X-Custom-Header' => 'custom-value',
        'X-Application-Name' => 'TestApp'
      })
      
      request = { method: :post, url: '/test' }
      processed_request = middleware.before_request(request)
      
      expect(processed_request[:headers]['X-Custom-Header']).to eq('custom-value')
      expect(processed_request[:headers]['X-Application-Name']).to eq('TestApp')
    end

    # Example 2: Response metadata middleware
    class ResponseMetadataMiddleware < AnthropicTools::Middleware::Base
      def before_request(request)
        request
      end

      def after_response(response)
        response[:_metadata] ||= {}
        response[:_metadata][:processed_at] = Time.now.iso8601
        response
      end
    end

    it "adds metadata to responses" do
      middleware = ResponseMetadataMiddleware.new
      
      response = { status: 200 }
      processed_response = middleware.after_response(response)
      
      expect(processed_response[:_metadata]).to be_a(Hash)
      expect(processed_response[:_metadata][:processed_at]).to match(/\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}/)
    end

    # Example 3: Request transformation middleware
    class RequestTransformationMiddleware < AnthropicTools::Middleware::Base
      def before_request(request)
        if request[:body]
          body = JSON.parse(request[:body])
          
          # Add a custom parameter to all requests
          body[:client_info] = {
            name: 'AnthropicTools Ruby Client',
            version: AnthropicTools::VERSION
          }
          
          request[:body] = body.to_json
        end
        
        request
      end

      def after_response(response)
        response
      end
    end

    it "transforms request bodies" do
      middleware = RequestTransformationMiddleware.new
      
      request = { 
        method: :post, 
        url: '/test', 
        body: '{"model":"claude-3"}'
      }
      
      processed_request = middleware.before_request(request)
      body = JSON.parse(processed_request[:body])
      
      expect(body['client_info']).to be_a(Hash)
      expect(body['client_info']['name']).to eq('AnthropicTools Ruby Client')
      expect(body['model']).to eq('claude-3')
    end

    # Example 4: Multiple middleware in a stack
    it "processes requests through multiple middleware in correct order" do
      stack = AnthropicTools::Middleware::Stack.new
      
      # Add middleware that adds headers
      header_middleware = CustomHeaderMiddleware.new({'X-Order' => '1'})
      stack.add(header_middleware)
      
      # Add middleware that modifies headers added by the first middleware
      class HeaderModifierMiddleware < AnthropicTools::Middleware::Base
        def before_request(request)
          request[:headers]['X-Order'] = "#{request[:headers]['X-Order']},2"
          request
        end

        def after_response(response)
          response
        end
      end
      
      modifier_middleware = HeaderModifierMiddleware.new
      stack.add(modifier_middleware)
      
      # Process request through the stack
      request = { method: :post, url: '/test', headers: {} }
      processed_request = stack.process_request(request)
      
      # Verify the order of processing
      expect(processed_request[:headers]['X-Order']).to eq('1,2')
    end
  end
end
