class EventsController < ApplicationController
  include AuthenticateRequest # Ensure this module is included

  before_action :authenticate_user, except: %i[index show]

  # GET /events
  def index
    @events = Event.all
    render json: @events
  end

  # GET /events/:id
  def show
    @event = Event.find(params[:id])
    render json: @event
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
    @event = Event.find(params[:id])
    if @event.update(event_params)
      render json: @event
    else
      render json: { errors: @event.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # DELETE /events/:id
  def destroy
    @event = Event.find(params[:id])
    @event.destroy
    head :no_content
  end

  private

  def event_params
    params.require(:event).permit(:name, :start_time, :odds, :status)
  end
end
