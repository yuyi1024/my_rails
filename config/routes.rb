Rails.application.routes.draw do
  root 'products#index'

  devise_for :users

  resources :products
  resources :images, only: [:create, :destroy]

  resource :carts, only: [:show, :destroy] do
  	collection do
  		post :add, path: 'add/:id', as: 'add'
  		post :change, path: 'change/:id', as: 'change'
		end
	end

  resources :orders do
    collection do
      get :ship_method, path: 'ship_method', as: 'ship_method'
      get :to_ezship, path: 'to_ezship/:process_id', as: 'to_ezship'
      post :from_ezship, path: 'from_ezship', as: 'from_ezship'
      get :get_user_data, path: 'get_user_data', as: 'get_user_data'
      get :remit_info, path: 'remit_info/:process_id', as: 'remit_info'
      post :checkout, path: 'checkout', as: 'checkout'
    end
  end
end


