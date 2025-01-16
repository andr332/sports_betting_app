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
    puts @event.errors.full_messages
    render json: { errors: @event.errors.full_messages }, status: :unprocessable_entity
  end
end


  def update
    return render json: { error: 'Event not found' }, status: :not_found if @event.nil?

    if @event.update(event_params)
      process_bet_results(@event) if @event.saved_change_to_attribute?(:result)
      render json: @event
    else
      render json: { errors: @event.errors.full_messages }, status: :unprocessable_entity
    end
  end


  def update_result
    return render json: { error: 'Event not found' }, status: :not_found if @event.nil?

    if @event.update(result: result_params[:result])
      render json: @event, status: :ok
    else
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

  # Only permit the result parameter for update_result
  def result_params
    params.permit(:result)
  end

  def process_bet_results(event)
    return unless event.present?

    event.bets.each do |bet|
      new_status = bet.predicted_outcome == event.result ? 'won' : 'lost'

      if bet.update(status: new_status)
        Rails.logger.info "Bet #{bet.id} updated to #{new_status}"
        redis = Redis.new(url: ENV['REDIS_URL'])
        redis.publish('bet_status_updated', { bet_id: bet.id, status: new_status }.to_json)
      else
        Rails.logger.error "Failed to update bet #{bet.id}: #{bet.errors.full_messages.join(', ')}"
      end
    end
  end
end
