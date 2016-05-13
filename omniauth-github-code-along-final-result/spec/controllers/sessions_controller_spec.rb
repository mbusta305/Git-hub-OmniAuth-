require 'rails_helper'
require 'spec_helper'

RSpec.describe SessionsController, type: :controller do
  before do
    request.env['omniauth.auth'] = OmniAuth.config.mock_auth[:github]
  end

  describe "#create" do
    it "should successfully create a user" do
      expect {
        post :create, provider: :github
      }.to change{ User.count }.by(1)
    end

    it 'is expected to successfully create a session' do
      expect(session[:user_id]).to be_nil
      post :create, provider: :github
      expect(session[:user_id]).not_to be_nil
    end


    it "is expected to redirect the user to the root url" do
      post :create, provider: :github
      expect(response).to redirect_to root_url
    end
  end

  describe "#destroy" do
    before do
      post :create, provider: :github
    end

    it "is expected to clear the session" do
      expect(session[:user_id]).not_to be_nil
      delete :destroy
      expect(session[:user_id]).to be_nil
    end

    it "is expected to redirect to the home page" do
      delete :destroy
      expect(response).to redirect_to root_url
    end
  end
end
