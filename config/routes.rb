Rails.application.routes.draw do
  root 'products#index'

  devise_for :users

  resources :products
  resources :images, only: [:create, :destroy]
end
