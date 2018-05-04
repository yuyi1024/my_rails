Rails.application.routes.draw do
  root 'products#index'

  devise_for :users

  resources :products
  resources :images, only: [:create, :destroy]

  resource :carts, only: [:show, :destroy] do
  	collection do
      get :checkout, path: 'checkout', as: 'checkout'
      get :ship_method, path: 'ship_method', as: 'ship_method' 
  		post :add, path: 'add/:id', as: 'add'
  		post :change, path: 'change/:id', as: 'change'
		end
	end

  resources :orders do
    collection do
      post :checkout, path: 'checkout', as: 'checkout'
      post :ezship, path: 'ezship', as: 'ezship'
      get :ship_method, path: 'ship_method', as: 'ship_method'
      get :remit_info, path: 'remit_info/:process_id', as: 'remit_info'
    end
  end
end
