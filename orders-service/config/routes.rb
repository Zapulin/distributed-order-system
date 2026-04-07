Rails.application.routes.draw do
  resources :orders, only: [ :create, :show ]

  get "up" => "rails/health#show", as: :rails_health_check
end
