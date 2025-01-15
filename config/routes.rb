Rails.application.routes.draw do
  mount Rswag::Api::Engine => '/api-docs'
  mount Rswag::Ui::Engine => '/api-docs'
  post 'signup', to: 'users#create'
  post 'login', to: 'sessions#create'
  get 'profile', to: 'users#profile'
end
