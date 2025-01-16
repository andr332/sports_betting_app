class ApplicationController < ActionController::API
  # Handle Record Not Found errors globally
  rescue_from ActiveRecord::RecordNotFound, with: :record_not_found

  private

  # Method to handle Record Not Found errors
  def record_not_found(exception)
    render json: { error: exception.message }, status: :not_found
  end
end
