require "bundler/setup"
require "anthropic_tools"

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end

# Helper to stub HTTP requests
def stub_anthropic_api(response_body, status: 200)
  connection = instance_double(Faraday::Connection)
  response = instance_double(
    Faraday::Response, 
    status: status, 
    body: response_body
  )
  
  allow(Faraday).to receive(:new).and_return(connection)
  allow(connection).to receive(:post).and_return(response)
  
  [connection, response]
end
