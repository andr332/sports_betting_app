Rails.application.routes.draw do
  # Use `resources` to follow RESTful conventions
  resources :results, only: [:index]

  # Swagger API Documentation
  mount Rswag::Api::Engine => '/api-docs'
  mount Rswag::Ui::Engine => '/api-docs'

  # User Routes
  post 'signup', to: 'users#create'
  post 'login', to: 'sessions#create'
  get 'profile', to: 'users#profile'
  put 'profile', to: 'users#update_profile'
  delete 'profile', to: 'users#destroy'

  # Bet Routes
  resources :bets, only: [:create, :index, :show]  # Fetch bets for current_user
  get '/users/:user_id/bets', to: 'bets#user_bets' # Fetch bets for a specific user (admin use)

  # Event Routes
  resources :events, only: [:index, :show, :create, :update, :destroy] do
    patch :update_result, on: :member  # New route for updating result only
  end

  # Leaderboard Route
  get 'leaderboard', to: 'leaderboards#index'
end
