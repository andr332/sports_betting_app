class ResultsController < ApplicationController
  def index
    results = ResultType.pluck(:name)
    render json: {
      event_results: results,
      prediction_outcomes: results
    }, status: :ok
  end
end
