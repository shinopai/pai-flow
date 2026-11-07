require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'validations' do
    it '有効な属性であれば有効であること' do
      user = User.new(
        name: 'テストユーザー',
        email: 'test@example.com',
        password: 'password123',
        password_confirmation: 'password123'
      )

      expect(user).to be_valid
    end
  end
end
