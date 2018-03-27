Rails.application.routes.draw do
  root 'pages#index'

  resources :products
  resources :images, only: [:create, :destroy]
end
