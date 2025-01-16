Rails.application.routes.draw do
  # Swagger API Documentation
  mount Rswag::Api::Engine => '/api-docs'
  mount Rswag::Ui::Engine => '/api-docs'

  # User Routes
  post 'signup', to: 'users#create'          # User Signup
  post 'login', to: 'sessions#create'        # User Login
  get 'profile', to: 'users#profile'         # View Profile
  put 'profile', to: 'users#update_profile'  # Update Profile
  delete 'profile', to: 'users#destroy'      # Delete Account

  # Bet Routes
  resources :bets, only: [:create, :index]          # Place a bet and view bet history
  get '/users/:user_id/bets', to: 'bets#index'      # View bets of a specific user

  # Event Routes
  resources :events, only: [:index, :show, :create, :update, :destroy] # Manage events

  # Leaderboard Route
  get 'leaderboard', to: 'leaderboards#index'       # View leaderboard
end
