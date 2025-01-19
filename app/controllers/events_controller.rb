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
      process_bet_results(@event) if @event.saved_change_to_attribute?(:result)
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

      if @event.saved_change_to_result?
        Rails.logger.info("Processing bets for event #{@event.id} after result change.")
        process_bet_results(@event)
      end

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

  def process_bet_results(event)
    return unless event.present?

    Rails.logger.info("Processing bets for event #{event.id}. Result: #{event.result}")

    redis = Redis.new(url: ENV['REDIS_URL'])

    event.bets.each do |bet|
      new_status = bet.predicted_outcome == event.result ? 'won' : 'lost'
      winnings = new_status == 'won' ? bet.amount.to_f * bet.odds.to_f : 0.0  

      if bet.update(status: new_status, winnings: winnings)
        Rails.logger.info("Bet #{bet.id} updated to #{new_status} with winnings: #{winnings}")

        redis.publish('bet_status_updated', { bet_id: bet.id, status: new_status }.to_json)

        if new_status == 'won'
          Rails.logger.info("Checking leaderboard for user #{bet.user_id} before update...")

          leaderboard = Leaderboard.find_or_initialize_by(user_id: bet.user_id)
          old_winnings = leaderboard.total_winnings.to_f

          leaderboard.total_winnings ||= 0
          leaderboard.total_winnings += winnings
          leaderboard.save!

          Rails.logger.info("Leaderboard for user #{bet.user_id} updated. Old winnings: #{old_winnings}, New winnings: #{leaderboard.total_winnings}")

          ProcessWinningsJob.perform_async(bet.user_id, winnings.to_f)

          redis.publish('leaderboard_updated', { user_id: bet.user_id, total_winnings: leaderboard.total_winnings.to_f }.to_json)
          redis.publish('bet_winning_updated', { user_id: bet.user_id, winnings: winnings.to_f, bet_id: bet.id }.to_json)
        end
      else
        Rails.logger.error("Failed to update bet #{bet.id}: #{bet.errors.full_messages.join(', ')}")
      end
    end
  end
end
