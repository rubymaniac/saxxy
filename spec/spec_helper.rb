require "bundler/setup"
require "rspec"
require "saxxy"
require "saxxy/parsers/nokogiri"
unless RUBY_PLATFORM == "java"
  require "saxxy/parsers/libxml"
  require "saxxy/parsers/ox"
end
require "pry"


Dir[File.dirname(__FILE__) + "/support/**/*.rb"].each(&method(:require))

Bundler.require(:default)

RSpec.configure do |config|
  config.treat_symbols_as_metadata_keys_with_true_values = true

  if RUBY_PLATFORM == "java"
    config.filter_run_excluding :not_jruby
  end

  config.mock_with :rspec

  config.before(:each) do
    FakeWeb.clean_registry
  end
end