require 'swagger_helper'

RSpec.describe "Events API", type: :request do
  let(:user) { create(:user) }
  let!(:event) { create(:event, name: 'Basketball Game', start_time: Time.now + 1.day, odds: 2.5, status: 'upcoming', result: nil) }

  let!(:bet1) { create(:bet, user: user, event: event, amount: 100, odds: 2.5, predicted_outcome: "win") }
  let!(:bet2) { create(:bet, user: user, event: event, amount: 50, odds: 2.1, predicted_outcome: "lose") }

  let(:valid_attributes) do
    { name: 'Basketball Game', start_time: Time.now + 2.days, odds: 3.0, status: 'upcoming', result: nil }
  end

  let(:invalid_attributes) do
    {
      name: nil,
      start_time: Time.now + 2.days,
      odds: -1,
      status: 'invalid_status',
      result: nil
    }
  end


  let(:auth_headers) do
    post '/login', params: { email: user.email, password: user.password }
    json = JSON.parse(response.body)
    { "Authorization" => "Bearer #{json['token']}" }
  end

  let(:Authorization) { auth_headers["Authorization"] }

  path '/events' do
    get 'List all events' do
      tags 'Events'
      produces 'application/json'

      response '200', 'events retrieved' do
        run_test! do
          get "/events", headers: auth_headers
          expect(response).to have_http_status(:ok)

          json_response = JSON.parse(response.body)
          expect(json_response.size).to be > 0

          first_event = json_response.first
          expect(first_event).to include('bets_count')
          expect(first_event['bets_count']).to eq(2)  
        end
      end
    end
  end

  # Show Event (Include bets_count)
  path '/events/{id}' do
    get 'Show a specific event' do
      tags 'Events'
      produces 'application/json'
      parameter name: :id, in: :path, type: :string, description: 'ID of the event'

      response '200', 'event retrieved' do
        let(:id) { event.id }
        run_test! do
          get "/events/#{id}", headers: auth_headers
          expect(response).to have_http_status(:ok)

          json_response = JSON.parse(response.body)
          expect(json_response['name']).to eq(event.name)
          expect(json_response).to include('bets_count')
          expect(json_response['bets_count']).to eq(2)
        end
      end

      response '404', 'event not found' do
        let(:id) { 'invalid-id' }
        run_test!
      end
    end
  end

# Create Event
path '/events' do
  post 'Create a new event' do
    tags 'Events'
    consumes 'application/json'
    security [{ bearerAuth: [] }]
    parameter name: :event, in: :body, schema: {
      type: :object,
      properties: {
        name: { type: :string },
        start_time: { type: :string, format: :date_time },
        odds: { type: :number },
        status: { type: :string },
        result: { type: :string, nullable: true }
      },
      required: ['name', 'start_time', 'odds', 'status']
    }

    response '201', 'event created' do
      let(:event_params) { { event: valid_attributes } }

      before do
        post '/events',
             params: event_params.to_json,
             headers: auth_headers.merge({ "CONTENT_TYPE" => "application/json" })
      end

      run_test! do
        expect(response).to have_http_status(:created)
        json_response = JSON.parse(response.body)

        expect(json_response['name']).to eq(valid_attributes[:name])
        expect(json_response['result']).to be_nil
      end
    end
  end
end




  # Update Event
  path '/events/{id}' do
    put 'Update an event' do
      tags 'Events'
      consumes 'application/json'
      security [{ bearerAuth: [] }]
      parameter name: :id, in: :path, type: :string, description: 'ID of the event'
      parameter name: :event, in: :body, schema: {
        type: :object,
        properties: {
          name: { type: :string },
          start_time: { type: :string, format: :datetime },
          odds: { type: :number },
          status: { type: :string },
          result: { type: :string }  # result is required during updates
        },
        required: ['name', 'start_time', 'odds', 'status', 'result']  # result is required during update
      }

      response '200', 'event updated' do
        let(:id) { event.id }
        let(:event_attributes) { { name: 'Updated Event', start_time: Time.now + 3.days, odds: 3.5, status: 'ongoing', result: 'win' } }

        run_test! do
          put "/events/#{id}", params: { event: event_attributes }, headers: auth_headers
          expect(response).to have_http_status(:ok)
          expect(JSON.parse(response.body)['name']).to eq(event_attributes[:name])
          expect(JSON.parse(response.body)['result']).to eq('win')  # Expecting the result to be updated to 'win'
        end
      end

      response '404', 'event not found' do
        let(:id) { 'invalid-id' }
        let(:event_attributes) { valid_attributes }

        run_test! do
          put "/events/#{id}", params: { event: event_attributes }, headers: auth_headers
          expect(response).to have_http_status(:not_found)
        end
      end
    end
  end

  # Delete Event
  path '/events/{id}' do
    delete 'Delete an event' do
      tags 'Events'
      security [{ bearerAuth: [] }]
      parameter name: :id, in: :path, type: :string, description: 'ID of the event'

      response '204', 'event deleted' do
        let(:id) { event.id }
        let(:Authorization) { auth_headers['Authorization'] }

        run_test! do
          expect(response).to have_http_status(:no_content)
        end
      end

      response '404', 'event not found' do
        let(:id) { 'invalid-id' }
        let(:Authorization) { auth_headers['Authorization'] }

        run_test!
      end
    end
  end

  # Update Event Result
  path '/events/{id}/update_result' do
    patch 'Update result of an event' do
      tags 'Events'
      consumes 'application/json'
      security [{ bearerAuth: [] }]
      parameter name: :id, in: :path, type: :string, description: 'ID of the event'
      parameter name: :result, in: :body, schema: {
        type: :object,
        properties: {
          result: { type: :string, enum: ['win', 'lose', 'draw'] }
        },
        required: ['result']
      }

      let(:result) { { result: 'lose' } }

      response '200', 'result updated successfully' do
        let(:id) { event.id }

        run_test! do
          patch "/events/#{id}/update_result", params: result, headers: auth_headers
          expect(response).to have_http_status(:ok)
          expect(JSON.parse(response.body)['result']).to eq('lose')
        end
      end

      response '404', 'event not found' do
        let(:id) { 'invalid-id' }
        let(:result_update) { { result: 'win' } }

        run_test! do
          patch "/events/#{id}/update_result", params: result_update, headers: auth_headers
          expect(response).to have_http_status(:not_found)
        end
      end
    end
  end


end
