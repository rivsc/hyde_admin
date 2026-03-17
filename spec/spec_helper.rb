require 'yaml'
require 'fileutils'
require 'i18n'
require 'date'
require 'cgi'
require 'roda'
require_relative '../lib/hyde_admin/version'

# Load hyde_admin.ru but skip the `run` call at the end
app_code = File.read(File.expand_path('../../bin/hyde_admin.ru', __FILE__))
# Remove the final `run ...` line that starts the Rack server
app_code = app_code.sub(/^run\s+.*\z/m, '')
eval(app_code, binding, File.expand_path('../../bin/hyde_admin.ru', __FILE__), 1)

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups
end
