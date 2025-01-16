class EventsController < ApplicationController
  include AuthenticateRequest # Ensure this module is included

  before_action :authenticate_user, except: %i[index show]
  before_action :set_event, only: %i[show update destroy]

  # GET /events
  def index
    @events = Event.all
    render json: @events
  end

  # GET /events/:id
  def show
    if @event
      render json: @event
    else
      render json: { error: 'Event not found' }, status: :not_found
    end
  end

  # POST /events
  def create
    @event = Event.new(event_params)
    if @event.save
      render json: @event, status: :created
    else
      render json: { errors: @event.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # PUT /events/:id
  def update
    if @event.nil?
      render json: { error: 'Event not found' }, status: :not_found
      return
    end

    if @event.update(event_params)
      process_bet_results if @event.saved_change_to_attribute?(:result) # ✅ Process bets if result changes
      render json: @event
    else
      render json: { errors: @event.errors.full_messages }, status: :unprocessable_entity
    end
  end


  # DELETE /events/:id
  def destroy
    if @event
      @event.destroy
      head :no_content
    else
      render json: { error: 'Event not found' }, status: :not_found
    end
  end

  private

  # Set event before show, update, or destroy
  def set_event
    @event = Event.find_by(id: params[:id])
  end

  # Strong parameters
  def event_params
    params.require(:event).permit(:name, :start_time, :odds, :status, :result) # ✅ Added :result
  end

def process_bet_results
  @event.bets.each do |bet|
    # Check if the bet's predicted outcome matches the event's result
    if bet.predicted_outcome == @event.result
      bet.update(status: 'won') # Mark bet as 'won' if the prediction is correct
    else
      bet.update(status: 'lost') # Mark bet as 'lost' if the prediction is incorrect
    end
  end
end

end
