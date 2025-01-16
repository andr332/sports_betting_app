class EventsController < ApplicationController
  include AuthenticateRequest

  before_action :authenticate_user!, except: %i[index show]
  before_action :set_event, only: %i[show update destroy]

  def index
    @events = Event.all
    render json: @events
  end

  def show
    if @event
      render json: @event
    else
      render json: { error: 'Event not found' }, status: :not_found
    end
  end

  def create
    @event = Event.new(event_params)
    if @event.save
      render json: @event, status: :created
    else
      render json: { errors: @event.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    if @event.nil?
      render json: { error: 'Event not found' }, status: :not_found
      return
    end

    if @event.update(event_params)
      process_bet_results if @event.saved_change_to_attribute?(:result)
      render json: @event
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

  def process_bet_results
    @event.bets.each do |bet|
      new_status = bet.won? ? 'won' : 'lost'
      bet.update!(status: new_status)

      redis = Redis.new(url: ENV['REDIS_URL'])
      redis.publish('bet_status_updated', { bet_id: bet.id, status: new_status }.to_json)
    end
  end
end
