require 'rubygems'

ENV["RAILS_ENV"] ||= 'test'
require File.expand_path("../../config/environment", __FILE__)
require 'rspec/rails'
require 'rspec/autorun'

OmniAuth.config.test_mode = true
omniauth_hash = {
                  'provider' => 'github',
                  'uid' => '5073754',
                  'info' => {
                    'name' => 'Jose',
                    'email' => 'jose@joseworks.org',
                    'nickname' => 'JoseWorks'
                  },
                  'extra' => {
                    'raw_info' => {
                      'location' => 'Eastern Shores',
                      'gravatar_id' => '123456789'
                    }
                  }
                }

OmniAuth.config.add_mock(:github, omniauth_hash)
Dir[Rails.root.join("spec/support/**/*.rb")].each { |f| require f }
ActiveRecord::Migration.check_pending! if defined?(ActiveRecord::Migration)

RSpec.configure do |config|
  config.include FactoryGirl::Syntax::Methods
  config.fixture_path = "#{::Rails.root}/spec/fixtures"
  config.use_transactional_fixtures = true
  config.infer_base_class_for_anonymous_controllers = false
  config.order = "random"

  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end
end
