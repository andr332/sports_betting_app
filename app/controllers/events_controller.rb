class EventsController < ApplicationController
  include AuthenticateRequest

  before_action :authenticate_user!, except: %i[index show]
  before_action :set_event, only: %i[show update destroy update_result]

  def index
    @events = Event.left_joins(:bets).select("events.*, COUNT(bets.id) AS bets_count").group("events.id")
    render json: @events.as_json(
      only: [:id, :name, :start_time, :odds, :status, :result],
      methods: [:bets_count]
    )
  end

  def show
    if @event
      bets_count = @event.bets.count
      render json: @event.as_json(
        only: [:id, :name, :start_time, :odds, :status, :result],
        methods: [:bets_count]
      ).merge(bets_count: bets_count)
    else
      render json: { error: 'Event not found' }, status: :not_found
    end
  end

  def create
    @event = Event.new(event_params)

    if @event.save
      render json: @event, status: :created
    else
      Rails.logger.error("Failed to create event: #{@event.errors.full_messages.join(', ')}")
      render json: { errors: @event.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    return render json: { error: 'Event not found' }, status: :not_found if @event.nil?

    if @event.update(event_params)
      render json: @event
    else
      Rails.logger.error("Failed to update event #{@event.id}: #{@event.errors.full_messages.join(', ')}")
      render json: { errors: @event.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update_result
    Rails.logger.info("Received request to update result for event ID: #{params[:id]} with params: #{params}")

    return render json: { error: 'Event not found' }, status: :not_found if @event.nil?

    Rails.logger.info("Event found: #{@event.as_json(only: [:id, :name, :status, :result])}")

    unless @event.status == 'completed'
      Rails.logger.warn("Attempt to update result for an event that is not completed. Event ID: #{@event.id}, Status: #{@event.status}")
      return render json: { error: 'Result can only be updated when the event is completed' }, status: :unprocessable_entity
    end

    previous_result = @event.result
    if @event.update(result: result_params[:result])
      Rails.logger.info("Successfully updated event #{@event.id}. Previous result: #{previous_result}, New result: #{result_params[:result]}")

      Rails.logger.info("Returning updated event response: #{@event.as_json(only: [:id, :name, :start_time, :status, :result])}")
      render json: @event.as_json(only: [:id, :name, :start_time, :status, :result]), status: :ok
    else
      Rails.logger.error("Failed to update event #{@event.id}. Errors: #{@event.errors.full_messages.join(', ')}")
      render json: { errors: @event.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    if @event
      @event.destroy
      head :no_content
    else
      render json: { error: 'Event not found' }, status: :not_found
    end
  end

  private

  def set_event
    @event = Event.find_by(id: params[:id])
  end

  def event_params
    params.require(:event).permit(:name, :start_time, :odds, :status, :result)
  end

  def result_params
    params.permit(:result)
  end
end
