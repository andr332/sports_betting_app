require 'swagger_helper'

RSpec.describe 'Users API', type: :request do
  # Signup Endpoint
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
        run_test! do
          parsed_body = JSON.parse(response.body)
          expect(parsed_body).to include('token', 'user')
          expect(parsed_body['user']).to include('id', 'name', 'email')
        end
      end

      response '422', 'unprocessable entity' do
        # Ensure no Authorization header is set
        let(:headers) { {} }
        let(:user) { { name: '', email: '', password: '', password_confirmation: '' } }
        run_test! do
          parsed_body = JSON.parse(response.body)
          expect(parsed_body).to include('errors')
        end
      end
    end
  end


  # Login Endpoint
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
        run_test! do
          parsed_body = JSON.parse(response.body)
          expect(parsed_body).to include('token', 'user')
          expect(parsed_body['user']).to include('id', 'name', 'email')
        end
      end

      response '401', 'unauthorized' do
        let!(:user) { User.create!(name: 'John Doe', email: 'john@example.com', password: 'password123') }
        let(:credentials) { { email: 'john@example.com', password: 'wrongpassword' } }
        run_test! do
          parsed_body = JSON.parse(response.body)
          expect(parsed_body).to include('error')
          expect(parsed_body['error']).to eq('Invalid email or password') # Optional: Ensure specific error message
        end
      end
    end
  end


  # Profile Retrieval Endpoint
  path '/profile' do
    get 'Get User Profile' do
      tags 'Users'
      produces 'application/json'
      security [{ bearerAuth: [] }] # Requires authentication

      response '200', 'profile retrieved' do
        let!(:user) { User.create!(name: 'John Doe', email: 'john@example.com', password: 'password123') }
        let(:Authorization) { "Bearer #{JWT.encode({ user_id: user.id }, ENV.fetch('JWT_SECRET', 'test_secret_key'))}" }
        run_test! do
          expect(JSON.parse(response.body)).to include('id', 'name', 'email')
        end
      end

      response '401', 'unauthorized' do
        let(:Authorization) { nil } # No token provided
        run_test! do
          expect(JSON.parse(response.body)).to include('error')
        end
      end
    end
  end

  # Update Profile Endpoint
  path '/profile' do
    put 'Update User Profile' do
      tags 'Users'
      consumes 'application/json'
      security [{ bearerAuth: [] }]
      parameter name: :user, in: :body, schema: {
        type: :object,
        properties: {
          name: { type: :string },
          email: { type: :string },
          password: { type: :string },
          password_confirmation: { type: :string }
        },
        required: ['name', 'email'] # Add 'password' if necessary
      }

      response '200', 'profile updated' do
        let!(:user_record) { User.create!(name: 'John Doe', email: 'john@example.com', password: 'password123') }
        let(:Authorization) { "Bearer #{JWT.encode({ user_id: user_record.id }, ENV.fetch('JWT_SECRET', 'test_secret_key'))}" }
        let(:user) { { name: 'Updated Name', email: 'updated@example.com', password: 'newpassword123', password_confirmation: 'newpassword123' } }
        run_test! do
          expect(JSON.parse(response.body)).to include('id', 'name', 'email')
        end
      end
    end
  end


  # Delete Profile Endpoint
  path '/profile' do
    delete 'Delete User Account' do
      tags 'Users'
      security [{ bearerAuth: [] }] # Requires authentication

      response '200', 'account deleted' do
        let!(:user) { User.create!(name: 'John Doe', email: 'john@example.com', password: 'password123') }
        let(:Authorization) { "Bearer #{JWT.encode({ user_id: user.id }, ENV.fetch('JWT_SECRET', 'test_secret_key'))}" }
        run_test! do
          expect(JSON.parse(response.body)).to include('message')
        end
      end

      response '401', 'unauthorized' do
        let(:Authorization) { nil }
        run_test!
      end
    end
  end
end
