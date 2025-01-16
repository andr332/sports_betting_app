require 'swagger_helper'

RSpec.describe "Bets API", type: :request do
  let(:user) { create(:user) }
  let(:event) { create(:event) }

  let(:valid_attributes) { { amount: 100, odds: 2.5, event_id: event.id, predicted_outcome: "Team A Wins" } }
  let(:invalid_attributes) { { amount: nil, odds: nil, event_id: nil, predicted_outcome: nil } }

  let(:auth_headers) do
    post '/login', params: { email: user.email, password: user.password }
    json = JSON.parse(response.body)
    { "Authorization" => "Bearer #{json['token']}" }
  end

  path '/bets' do
    get 'Fetch all bets for the authenticated user' do
      tags 'Bets'
      security [{ bearerAuth: [] }]
      produces 'application/json'

      response '200', 'Bets retrieved successfully' do
        let(:Authorization) { auth_headers["Authorization"] }
        before do
          create(:bet, user: user, event: event, predicted_outcome: "Team A Wins")
          create(:bet, user: user, event: event, predicted_outcome: "Team B Wins")
        end

        run_test! do
          expect(response).to have_http_status(:ok)
          bets = JSON.parse(response.body)
          expect(bets.size).to eq(2)
        end
      end

      response '401', 'Unauthorized request' do
        let(:Authorization) { nil } # No token provided

        run_test! do
          expect(response).to have_http_status(:unauthorized)
        end
      end
    end

    post 'Creates a new bet' do
      tags 'Bets'
      consumes 'application/json'
      security [{ bearerAuth: [] }]
      parameter name: :bet, in: :body, schema: {
        type: :object,
        properties: {
          amount: { type: :number },
          odds: { type: :number },
          event_id: { type: :string },
          predicted_outcome: { type: :string }
        },
        required: ['amount', 'odds', 'event_id', 'predicted_outcome']
      }

      response '201', 'Bet created' do
        let(:bet) { valid_attributes }
        let(:Authorization) { auth_headers["Authorization"] }

        run_test! do
          expect(response).to have_http_status(:created)
          expect(JSON.parse(response.body)['amount'].to_f).to eq(100.0)
          expect(JSON.parse(response.body)['status']).to eq('pending')
        end
      end

      response '422', 'Unprocessable entity' do
        let(:bet) { invalid_attributes }
        let(:Authorization) { auth_headers["Authorization"] }

        run_test! do
          expect(response).to have_http_status(:unprocessable_entity)
          expect(JSON.parse(response.body)).to include('errors')
        end
      end
    end
  end

  path '/users/{user_id}/bets' do
    get 'Returns a user\'s bets' do
      tags 'Bets'
      security [{ bearerAuth: [] }]
      parameter name: :user_id, in: :path, type: :string

      response '200', 'returns user\'s bets' do
        let(:user_id) { user.id }
        let(:Authorization) { auth_headers["Authorization"] }
        before do
          create(:bet, user: user, event: event, predicted_outcome: "Team A Wins")
        end

        run_test! do
          expect(response).to have_http_status(:ok)
          expect(JSON.parse(response.body).size).to eq(1)
          expect(JSON.parse(response.body).first['status']).to eq('pending')
        end
      end
    end
  end
end
