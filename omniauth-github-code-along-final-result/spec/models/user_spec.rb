require 'spec_helper'

RSpec.describe User, type: :model do
  describe "create user" do
    def valid_attributes
      { provider:  "github",
       uid:  "1234567",
       name:  'Jose'}
    end

    context 'with invalid attributes' do
      it 'does not creates a user without a provider' do
        user = User.create(valid_attributes.merge(provider: ''))
        expect(User.count).to eq(0)
      end
    end
    context 'with valid attributes' do
      it 'creates a user' do
        user = User.create(valid_attributes)
        expect(User.count).to eq(1)
      end
      it 'creates a user' do
        user = User.create(valid_attributes)
        expect(user.provider).to eq( "github")
      end
    end
  end
end
