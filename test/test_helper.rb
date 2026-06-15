ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'
require 'minitest/mock' # provides Object#stub used by BpApiStubs#with_bp

# Stand-in for LinkedData::Client::Models::User — the BioPortal API user object the
# app stores in session and reads (.username/.admin?/.apikey/.email/.firstName/.lastName).
FakeBpUser = Struct.new(:username, :firstName, :lastName, :email, :apikey, :admin,
                        :errors, :error, keyword_init: true) do
  def admin?
    !!admin
  end

  # The real client User responds to to_hash (app/views/layouts/_header.html.erb).
  def to_hash
    to_h
  end
end

# Stub the app's two BioPortal API boundaries so tests never hit the network.
module BpApiStubs
  def fake_bp_user(username: 'tester', admin: false, first: 'Test', last: 'User',
                   email: 'tester@example.com', apikey: 'APIKEY', errors: nil, error: nil)
    FakeBpUser.new(username: username, firstName: first, lastName: last, email: email,
                   apikey: apikey, admin: admin, errors: errors, error: error)
  end

  # Stub User.authenticate (login) and User.get (lookup) to return `user` for the block.
  def with_bp(user)
    LinkedData::Client::Models::User.stub(:authenticate, user) do
      LinkedData::Client::Models::User.stub(:get, user) do
        yield
      end
    end
  end

  def login_as(user, password: 'secret')
    post '/login', params: { user: { username: user.username, password: password } }
  end
end

class ActiveSupport::TestCase
  # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
  fixtures :all
end

class ActionDispatch::IntegrationTest
  include BpApiStubs
  setup { ActionMailer::Base.deliveries.clear }
end
