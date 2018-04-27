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
  		post :add, path: 'add/:id'
  		post :change, path: 'change/:id'
		end
	end

  resources :orders do
    collection do
      post :ezship, path: 'ezship', as: 'ezship'
      get :ship_method, path: 'ship_method', as: 'ship_method'
      get :remit_info, path: 'remit_info/:process_id', as: 'remit_info'
    end
  end

  namespace :console do
    root 'dashboards#index'
    resources :users
    resources :products
    resources :orders, only: [:index, :show, :edit, :update] do 
      collection do
        
      end
    end
  end
end
