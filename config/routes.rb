Rails.application.routes.draw do
  root 'pages#index'

  resources :products

end
