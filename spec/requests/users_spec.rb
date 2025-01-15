require 'swagger_helper'

RSpec.describe 'Users API', type: :request do
  path '/signup' do
    post 'User Signup' do
      tags 'Users'
      consumes 'application/json'
      parameter name: :user, in: :body, schema: {
        type: :object,
        properties: {
          name: { type: :string },
          email: { type: :string },
          password: { type: :string },
          password_confirmation: { type: :string }
        },
        required: ['name', 'email', 'password', 'password_confirmation']
      }

      response '201', 'user created' do
        let(:user) { { name: 'John Doe', email: 'john@example.com', password: 'password123', password_confirmation: 'password123' } }
        run_test!
      end

      response '422', 'unprocessable entity' do
        let(:user) { { name: '', email: '', password: '', password_confirmation: '' } }
        run_test!
      end
    end
  end

  path '/login' do
    post 'User Login' do
      tags 'Users'
      consumes 'application/json'
      parameter name: :credentials, in: :body, schema: {
        type: :object,
        properties: {
          email: { type: :string },
          password: { type: :string }
        },
        required: ['email', 'password']
      }

      response '200', 'login successful' do
        let!(:user) { User.create!(name: 'John Doe', email: 'john@example.com', password: 'password123') }
        let(:credentials) { { email: 'john@example.com', password: 'password123' } }
        run_test!
      end

      response '401', 'unauthorized' do
        let(:credentials) { { email: 'john@example.com', password: 'wrongpassword' } }
        run_test!
      end
    end
  end
end
