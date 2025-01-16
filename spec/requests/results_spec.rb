require 'swagger_helper'

RSpec.describe "Results API", type: :request do
  let!(:result_types) { %w[win lose draw penalty extra_time disqualified] }

  before do
    result_types.each { |name| ResultType.create!(name: name) }
  end

  path '/results' do
    get 'Get all possible result types' do
      tags 'Results'
      produces 'application/json'

      response '200', 'results retrieved successfully' do
        run_test! do
          get "/results"

          expect(response).to have_http_status(:ok)
          json_response = JSON.parse(response.body)

          expect(json_response).to be_a(Hash)  # ✅ Fix: Expecting a hash
          expect(json_response).to include("event_results", "prediction_outcomes")

          expect(json_response["event_results"]).to be_an(Array)
          expect(json_response["prediction_outcomes"]).to be_an(Array)

          expect(json_response["event_results"]).to match_array(result_types)
          expect(json_response["prediction_outcomes"]).to match_array(result_types)
        end
      end
    end
  end
end
