require 'swagger_helper'

RSpec.describe "Events API", type: :request do
  let(:user) { create(:user) }
  let!(:event) { create(:event, name: 'Football Match', start_time: Time.now + 1.day, odds: 2.5, status: 'upcoming', result: 'win') }

  let(:valid_attributes) do
    { name: 'Basketball Game', start_time: Time.now + 2.days, odds: 3.0, status: 'upcoming', result: nil }
  end

  # ✅ Define invalid attributes that will trigger validation failure
  let(:invalid_attributes) do
    { name: nil, start_time: nil, odds: 2.5, status: 'invalid', result: nil }
  end


  let(:auth_headers) do
    post '/login', params: { email: user.email, password: user.password }
    json = JSON.parse(response.body)
    { "Authorization" => "Bearer #{json['token']}" }
  end

  # ✅ Fix: Ensure authorization is set for every request
  let(:Authorization) { auth_headers["Authorization"] }

  # List Events
  path '/events' do
    get 'List all events' do
      tags 'Events'
      produces 'application/json'

      response '200', 'events retrieved' do
        run_test! do
          get "/events", headers: auth_headers
          expect(response).to have_http_status(:ok)
          expect(JSON.parse(response.body).size).to be > 0
        end
      end
    end
  end
  # Show Event
  path '/events/{id}' do
    get 'Show a specific event' do
      tags 'Events'
      produces 'application/json'
      parameter name: :id, in: :path, type: :string, description: 'ID of the event'

      response '200', 'event retrieved' do
        let(:id) { event.id }
        run_test! do
          expect(response).to have_http_status(:ok)
          expect(JSON.parse(response.body)['name']).to eq(event.name)
        end
      end

      response '404', 'event not found' do
        let(:id) { 'invalid-id' }
        run_test!
      end
    end
  end

  path '/events' do
    post 'Create a new event' do
      tags 'Events'
      consumes 'application/json'
      security [{ bearerAuth: [] }]
      parameter name: :event, in: :body, schema: {
        type: :object,
        properties: {
          name: { type: :string },
          start_time: { type: :string, format: :datetime },
          odds: { type: :number },
          status: { type: :string }
          # result is removed from the body for creation
        },
        required: ['name', 'start_time', 'odds', 'status']  # result is not required here
      }

      response '201', 'event created' do
        let(:Authorization) { auth_headers['Authorization'] }
        let(:event) { valid_attributes }

        run_test! do
          expect(response).to have_http_status(:created)
          expect(JSON.parse(response.body)['name']).to eq(valid_attributes[:name])
          expect(JSON.parse(response.body)['result']).to be_nil  # result should be nil when created
        end
      end

      response '422', 'unprocessable entity' do
        let(:Authorization) { auth_headers['Authorization'] }
        let(:event) { invalid_attributes }

        run_test! do
          expect(response).to have_http_status(:unprocessable_entity)
          expect(JSON.parse(response.body)).to include('errors')
        end
      end
    end
  end



  #Update Event
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
end
