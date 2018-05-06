Rails.application.routes.draw do
  root 'products#index'


  devise_for :users, controllers: {
    sessions: 'users/sessions',
    registrations: 'users/registrations'
  }

  devise_scope :user do
    get '/user/show', to: 'users/registrations#show'
    get '/user/order_list', to: 'users/registrations#order_list'
    get '/user/pwd_field', to: 'users/registrations#pwd_field'
    patch '/user/update_field', to: 'users/registrations#update_field'
  end

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
      get :cash_card, path: 'cash_card/:process_id', as: 'cash_card'
      post :paid, path: 'paid/:process_id', as: 'paid'
    end
  end

end


