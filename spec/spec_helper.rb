require "bundler/setup"
require "anthropic_tools"
require "webmock/rspec"
require "vcr"

# Configure VCR
VCR.configure do |config|
  config.cassette_library_dir = "spec/fixtures/vcr_cassettes"
  config.hook_into :webmock
  config.configure_rspec_metadata!
  
  # Filter out sensitive data
  config.filter_sensitive_data('<ANTHROPIC_API_KEY>') { ENV['ANTHROPIC_API_KEY'] || 'test_api_key' }
  
  # Allow VCR to record new HTTP interactions when no cassette exists
  config.default_cassette_options = {
    record: :new_episodes,
    match_requests_on: [:method, :uri, :body]
  }
end

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
def stub_anthropic_api(response_body, status: 200, headers: {})
  connection = instance_double(Faraday::Connection)
  response = instance_double(
    Faraday::Response, 
    status: status, 
    body: response_body,
    headers: headers.merge({'x-request-id' => 'req_test123'})
  )
  
  allow(Faraday).to receive(:new).and_return(connection)
  allow(connection).to receive(:post).and_return(response)
  
  [connection, response]
end
