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

          expect(json_response).to be_a(Hash) 
          expect(json_response).to include("event_results", "prediction_outcomes")

          expect(json_response["event_results"]).to be_an(Array)
          expect(json_response["prediction_outcomes"]).to be_an(Array)

          expect(json_response["event_results"]).to match_array(result_types)
          expect(json_response["prediction_outcomes"]).to match_array(result_types)
        end
      end
    end
  end

  path '/results/bulk_create' do
    post 'Bulk create result types' do
      tags 'Results'
      consumes 'application/json'
      parameter name: :body, in: :body, schema: {
        type: :object,
        properties: {
          result_types: {
            type: :array,
            items: { type: :string },
            example: ["goal", "foul", "own_goal"]
          }
        },
        required: ['result_types']
      }

      response '201', 'result types created successfully' do
        let(:body) { { result_types: ["goal", "foul", "own_goal"] } }

        run_test! do
          post "/results/bulk_create", params: body.to_json, headers: { "CONTENT_TYPE" => "application/json" }

          expect(response).to have_http_status(:created)
          json_response = JSON.parse(response.body)

          expect(json_response).to include("message", "results")
          expect(json_response["message"]).to eq("Result types created successfully")
          expect(json_response["results"]).to be_an(Array)
          expect(json_response["results"].map { |r| r["name"] }).to include("goal", "foul", "own_goal")
        end
      end

      response '422', 'unprocessable entity (invalid input)' do
        let(:body) { { result_types: nil } }

        run_test! do
          post "/results/bulk_create", params: body.to_json, headers: { "CONTENT_TYPE" => "application/json" }

          expect(response).to have_http_status(:unprocessable_entity)
          json_response = JSON.parse(response.body)

          expect(json_response).to include("error")
          expect(json_response["error"]).to eq("result_types must be an array with at least one value")
        end
      end

    end
  end
end
