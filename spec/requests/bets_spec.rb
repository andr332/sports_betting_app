require 'swagger_helper'

RSpec.describe "Bets API", type: :request do
  let(:user) { create(:user) }
  let(:event) { create(:event) }

  let(:valid_attributes) { { amount: 100, odds: 2.5, status: "pending", event_id: event.id } }
  let(:invalid_attributes) { { amount: nil, odds: nil, status: nil, event_id: nil } }

  # Simulate login and retrieve JWT token
  let(:auth_headers) do
    post '/login', params: { email: user.email, password: user.password }
    json = JSON.parse(response.body)
    { "Authorization" => "Bearer #{json['token']}" }
  end

  # POST /bets - Swagger Documentation for Bet Creation
  path '/bets' do
    post 'Creates a new bet' do
      tags 'Bets'
      consumes 'application/json'
      security [{ bearerAuth: [] }]  # Security: Bearer Token required
      parameter name: :bet, in: :body, schema: {
        type: :object,
        properties: {
          amount: { type: :number },
          odds: { type: :number },
          status: { type: :string },
          event_id: { type: :string }
        },
        required: ['amount', 'odds', 'status', 'event_id']
      }

      response '201', 'bet created' do
        let(:bet) { valid_attributes }
        let(:Authorization) { auth_headers["Authorization"] }  # Add Authorization header

        run_test! do
          expect(response).to have_http_status(:created)
          expect(JSON.parse(response.body)['amount'].to_f).to eq(100.0)
        end
      end

      response '422', 'unprocessable entity' do
        let(:bet) { invalid_attributes }
        let(:Authorization) { auth_headers["Authorization"] }  # Add Authorization header

        run_test! do
          expect(response).to have_http_status(:unprocessable_entity)
          expect(JSON.parse(response.body)).to include('errors')
        end
      end
    end
  end

  # GET /users/:user_id/bets - Swagger Documentation for Fetching User's Bets
  path '/users/{user_id}/bets' do
    get 'Returns a user\'s bets' do
      tags 'Bets'
      security [{ bearerAuth: [] }]  # Security: Bearer Token required
      parameter name: :user_id, in: :path, type: :string

      response '200', 'returns user\'s bets' do
        let(:user_id) { user.id }
        let(:Authorization) { auth_headers["Authorization"] }  # Add Authorization header
        before do
          create(:bet, user: user, event: event)
        end

        run_test! do
          expect(response).to have_http_status(:ok)
          expect(JSON.parse(response.body).size).to eq(1)
        end
      end
    end
  end
end
