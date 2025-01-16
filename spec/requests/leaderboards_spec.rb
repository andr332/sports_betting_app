require 'swagger_helper'

RSpec.describe "Leaderboards API", type: :request do
  let(:user) { create(:user) }
  let(:auth_headers) do
    post '/login', params: { email: user.email, password: user.password }
    json = JSON.parse(response.body)
    { "Authorization" => "Bearer #{json['token']}" }
  end

  before do
    # Create leaderboard entries for testing
    create_list(:leaderboard, 10, total_winnings: rand(100..1000), user: create(:user))
  end

  path '/leaderboard' do
    get 'Retrieve the leaderboard' do
      tags 'Leaderboard'
      produces 'application/json'
      security [{ bearerAuth: [] }]

      response '200', 'leaderboard retrieved' do
        let(:Authorization) { auth_headers['Authorization'] }

        run_test! do
          expect(response).to have_http_status(:ok)
          parsed_body = JSON.parse(response.body)
          expect(parsed_body).to be_an(Array)
          expect(parsed_body.size).to eq(10) # Assuming the API returns the top 10 players
          expect(parsed_body.first).to include('id', 'name', 'total_winnings')
        end
      end

      response '401', 'unauthorized' do
        let(:Authorization) { nil }

        run_test! do
          expect(response).to have_http_status(:unauthorized)
          parsed_body = JSON.parse(response.body)
          expect(parsed_body).to include('error' => 'Unauthorized access')
        end
      end
    end
  end
end
