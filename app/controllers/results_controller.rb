class ResultsController < ApplicationController
  def index
    results = ResultType.pluck(:name)
    render json: {
      event_results: results,
      prediction_outcomes: results
    }, status: :ok
  end

  def bulk_create
    result_names = params[:result_types] # Expecting an array of names
    return render json: { error: "result_types must be an array with at least one value" }, status: :unprocessable_entity if result_names.nil? || result_names.empty?

    created_results = []
    errors = []

    result_names.each do |name|
      begin
        # Find or create the result type
        result = ResultType.find_or_create_by!(name: name)
        created_results << result
      rescue ActiveRecord::RecordInvalid => e
        # If the result already exists, skip or log the error
        errors << { name: name, errors: e.message }
      end
    end

    if errors.empty?
      render json: { message: "Result types created successfully", results: created_results }, status: :created
    else
      render json: { message: "Some result types failed to save", errors: errors }, status: :unprocessable_entity
    end
  end

end
